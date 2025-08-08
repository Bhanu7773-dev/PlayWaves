import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import '../services/jiosaavn_api_service.dart';
import '../widgets/animated_navbar.dart';
import 'music_player.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final JioSaavnApiService _apiService = JioSaavnApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _bannerController = PageController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Timer? _bannerTimer;
  int _selectedNavIndex = 0;
  int _currentSongIndex = 0;

  List<Map<String, dynamic>> _trendingSongs = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _bannerSongs = [];
  List<Map<String, dynamic>> _currentPlaylist = [];

  bool _isLoading = true;
  bool _isSongLoading = false;
  String? _error;

  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
    _startBannerAutoScroll();

    // Listen to audio player state changes
    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          // Clear loading when song starts playing
          if (playing) {
            _isSongLoading = false;
          }
        });
      }
    });

    // Listen to player state to clear loading when ready
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted && state.processingState == ProcessingState.ready) {
        setState(() {
          _isSongLoading = false;
        });
      }
    });
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients && _bannerSongs.isNotEmpty) {
        final nextPage = (_bannerController.page?.round() ?? 0) + 1;
        if (nextPage >= _bannerSongs.length) {
          _bannerController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _bannerController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Add a known song with lyrics for testing
      final testSongWithLyrics = {
        'id': '3IoDK8qI', // Different song ID that should exist
        'name': 'Tum Hi Ho',
        'subtitle': 'Arijit Singh',
        'image': [
          {
            'quality': '500x500',
            'link':
                'https://c.saavncdn.com/191/Aashiqui-2-Hindi-2013-500x500.jpg',
          },
        ],
        'artists': {
          'primary': [
            {'name': 'Arijit Singh'},
          ],
        },
      };

      // Use different search queries to get varied content
      final List<String> songQueries = [
        'trending hindi songs',
        'bollywood hits',
        'latest punjabi songs',
        'romantic songs',
        'party songs',
        'english hits',
        'pop songs',
        'rock music',
        'hip hop',
        'electronic music',
        'indie songs',
        'classical music',
      ];

      final List<String> albumQueries = [
        'latest albums',
        'bollywood albums',
        'punjabi albums',
        'hindi albums',
        'new releases',
        'english albums',
        'pop albums',
        'rock albums',
        'hip hop albums',
        'electronic albums',
      ];

      final List<String> bannerQueries = [
        'top hits 2024',
        'viral songs',
        'trending now',
        'popular music',
        'chart toppers',
        'global hits',
        'billboard top',
        'spotify viral',
        'youtube trending',
      ];

      // Randomly select queries for variety
      final random = DateTime.now().millisecondsSinceEpoch;
      final songQuery = songQueries[random % songQueries.length];
      final albumQuery = albumQueries[random % albumQueries.length];
      final bannerQuery = bannerQueries[random % bannerQueries.length];

      final songsResponse = await _apiService.searchSongs(songQuery, limit: 10);
      final albumsResponse = await _apiService.searchAlbums(
        albumQuery,
        limit: 5,
      );

      // For banner, include the test song with lyrics
      final bannerResponse = await _apiService.searchSongs(
        bannerQuery,
        limit: 5,
      );

      // Search for individual famous artists (both Hindi and English)
      final List<String> famousArtists = [
        'arijit singh',
        'shreya ghoshal',
        'atif aslam',
        'neha kakkar',
        'armaan malik',
        'honey singh',
        'badshah',
        'guru randhawa',
        'taylor swift',
        'ed sheeran',
        'ariana grande',
        'justin bieber',
        'billie eilish',
        'the weeknd',
        'dua lipa',
        'bruno mars',
      ];

      // Get multiple individual artists
      List<Map<String, dynamic>> allArtists = [];

      // Shuffle the artists list for variety on each refresh
      final shuffledArtists = List<String>.from(famousArtists)..shuffle();

      for (int i = 0; i < 6; i++) {
        try {
          final artistName = shuffledArtists[i];
          final artistResponse = await _apiService.searchArtists(
            artistName,
            limit: 1,
          );

          if (artistResponse['success'] == true &&
              artistResponse['data'] != null &&
              artistResponse['data']['results'] != null &&
              artistResponse['data']['results'].isNotEmpty) {
            allArtists.add(artistResponse['data']['results'][0]);
          }
        } catch (e) {
          print('Error fetching artist: $e');
        }
      }

      if (songsResponse['success'] == true && songsResponse['data'] != null) {
        final songsData = songsResponse['data'];
        if (songsData['results'] != null) {
          final songs = List<Map<String, dynamic>>.from(songsData['results']);
          setState(() {
            _trendingSongs = songs;
          });
        }
      }

      if (albumsResponse['success'] == true && albumsResponse['data'] != null) {
        final albumsData = albumsResponse['data'];
        if (albumsData['results'] != null) {
          final albums = List<Map<String, dynamic>>.from(albumsData['results']);
          setState(() {
            _albums = albums;
          });
        }
      }

      // For banner, add the test song with lyrics as first item
      List<Map<String, dynamic>> bannerSongs = [testSongWithLyrics];

      if (bannerResponse['success'] == true && bannerResponse['data'] != null) {
        final bannerData = bannerResponse['data'];
        if (bannerData['results'] != null) {
          final banners = List<Map<String, dynamic>>.from(
            bannerData['results'],
          );
          bannerSongs.addAll(banners.take(4)); // Add 4 more songs
        }
      }

      setState(() {
        _bannerSongs = bannerSongs;
        _artists = allArtists;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          // Mini Music Player (when song is loaded)
          if (_currentSong != null)
            Positioned(
              bottom: 70, // Above navbar
              left: 16,
              right: 16,
              child: _buildMiniPlayer(),
            ),
          // Animated Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedNavBar(
              selectedIndex: _selectedNavIndex,
              onNavTap: _onNavTap,
              navIcons: const [
                Icons.home,
                Icons.search,
                Icons.playlist_play,
                Icons.person_outline,
              ],
              navLabels: const ['Home', 'Search', 'Playlist', 'Profile'],
            ),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (_selectedNavIndex == index) return;

    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Home - already here, do nothing
        break;
      case 1:
        // Navigate to Search with slide transition
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SearchPage(
              onNavTap: _onNavTap,
              selectedNavIndex: _selectedNavIndex,
              currentSong: _currentSong,
              audioPlayer: _audioPlayer,
              isSongLoading: _isSongLoading,
              onPlayPause: () {
                if (_audioPlayer.playing) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
              onNext: _playNextSong,
              onPrevious: _playPreviousSong,
              onSongChanged: (song) {
                if (mounted) {
                  setState(() {
                    _currentSong = song;
                    _isSongLoading = true; // Set loading when song changes
                  });
                }
              },
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _selectedNavIndex = 0;
            });
          }
        });
        break;
      case 2:
        // Navigate to Playlist
        break;
      case 3:
        // Navigate to Profile
        break;
    }
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Colors.black],
        ),
      ),
      child: Stack(children: List.generate(15, (index) => _buildMeteor(index))),
    );
  }

  Widget _buildMeteor(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: (index * 50.0) % MediaQuery.of(context).size.height,
          left: (index * 80.0) % MediaQuery.of(context).size.width,
          child: Transform.rotate(
            angle: 3.14159 * 1.2,
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 1,
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Colors.white70, Colors.transparent],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'PlayWaves',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Removed the search button - now handled by nav bar
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionCard(
          'Hot',
          'Trending',
          'Discover what\'s trending right now.',
          Colors.red,
          Icons.local_fire_department,
          () {},
        ),
        _buildActionCard(
          'Popular',
          'Most Played',
          'Check out the most played songs.',
          Colors.green,
          Icons.play_circle_filled,
          () {},
        ),
        _buildActionCard(
          'Collection',
          'Playlists',
          'Browse curated playlists for every mood.',
          Colors.purple,
          Icons.playlist_play,
          () {},
        ),
        _buildActionCard(
          'Stars',
          'Artists',
          'Explore your favorite artists.',
          Colors.blue,
          Icons.person,
          () {},
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String tag,
    String title,
    String description,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: color.withOpacity(0.15),
              ),
              child: Text(
                tag.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFff7d78)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFff7d78),
      backgroundColor: Colors.black,
      displacement: 40.0,
      strokeWidth: 3.0,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 100,
            ), // Add padding for navbar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildActionCards(),
                ),
                const SizedBox(height: 20),
                if (_bannerSongs.isNotEmpty) _buildBannerSection(),
                const SizedBox(height: 20),
                if (_albums.isNotEmpty) _buildAlbumsSection(),
                const SizedBox(height: 20),
                if (_artists.isNotEmpty) _buildArtistsSection(),
                if (_trendingSongs.isNotEmpty) _buildSongsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: _bannerSongs.length,
        itemBuilder: (context, index) {
          final song = _bannerSongs[index];
          return _buildBannerCard(song);
        },
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> song) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    final songId = song['id'];

    // Check if this is our test song with lyrics
    final hasLyrics = songId == 'PIzj2ULl';

    String artist = 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        artist = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['subtitle'] != null) {
      artist = song['subtitle'];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFff7d78).withOpacity(0.3),
                          const Color(0xFF9c27b0).withOpacity(0.3),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Lyrics indicator badge
          if (hasLyrics)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lyrics, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Lyrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Gradient overlay and content
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),

          // Play button and song info
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () => _playSong(song),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Featured Albums",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _albums.length,
            itemBuilder: (context, index) {
              final album = _albums[index];
              return _buildAlbumCard(album);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    final imageUrl = _getBestImageUrl(album['image']);
    final title = album['name'] ?? album['title'] ?? 'Unknown Album';
    final subtitle = album['subtitle'] ?? album['artist'] ?? 'Unknown Artist';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFff7d78).withOpacity(0.3),
                                  const Color(0xFF9c27b0).withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.album,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 160,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFff7d78).withOpacity(0.3),
                              const Color(0xFF9c27b0).withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.album,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFff7d78).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _playAlbum(album),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Popular Artists",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _artists.length,
            itemBuilder: (context, index) {
              final artist = _artists[index];
              return _buildArtistCard(artist);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    final imageUrl = _getBestImageUrl(artist['image']);
    final name = artist['name'] ?? artist['title'] ?? 'Unknown Artist';

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFff7d78).withOpacity(0.3),
                  const Color(0xFF9c27b0).withOpacity(0.3),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFff7d78).withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFff7d78).withOpacity(0.3),
                                const Color(0xFF9c27b0).withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFff7d78).withOpacity(0.3),
                            const Color(0xFF9c27b0).withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Trending Songs",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _trendingSongs.length,
          itemBuilder: (context, index) {
            final song = _trendingSongs[index];
            return _buildSongTile(song, index);
          },
        ),
      ],
    );
  }

  Widget _buildSongTile(Map<String, dynamic> song, int index) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';

    String subtitle = 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        subtitle = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['subtitle'] != null) {
      subtitle = song['subtitle'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFff7d78).withOpacity(0.3),
                    const Color(0xFF9c27b0).withOpacity(0.3),
                  ],
                ),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.music_note,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.music_note, color: Colors.white),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFff7d78),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            onPressed: () => _playSong(song),
          ),
        ),
      ),
    );
  }

  String? _getBestImageUrl(dynamic images) {
    if (images is List && images.isNotEmpty) {
      for (var img in images.reversed) {
        if (img is Map && img['link'] != null) {
          return img['link'];
        }
        if (img is Map && img['url'] != null) {
          return img['url'];
        }
      }
    } else if (images is String) {
      return images;
    }
    return null;
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    try {
      print('Attempting to play song: ${song['name']}');
      print('Song ID: ${song['id']}');

      // Set loading state
      setState(() {
        _isSongLoading = true;
      });

      // Stop current playback and reset position immediately
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);

      // Update current song immediately with all available data
      setState(() {
        _currentSong = Map<String, dynamic>.from(song);
        _currentPlaylist = _trendingSongs;
        _currentSongIndex = _trendingSongs.indexWhere(
          (s) => s['id'] == song['id'],
        );
        if (_currentSongIndex == -1) _currentSongIndex = 0;
      });

      final songId = song['id'];
      if (songId != null) {
        print('Fetching song details for ID: $songId');
        final songDetails = await _apiService.getSongById(songId);
        print('Song details response: $songDetails');

        String? downloadUrl;
        final songData = songDetails['data']?[0];

        if (songData != null) {
          print('Available keys in song data: ${songData.keys.toList()}');

          setState(() {
            _currentSong = Map<String, dynamic>.from(songData);
          });

          if (songData['downloadUrl'] != null &&
              songData['downloadUrl'] is List) {
            final downloadUrls = songData['downloadUrl'] as List;
            if (downloadUrls.isNotEmpty) {
              final urlData = downloadUrls.last;
              downloadUrl = urlData['url'] ?? urlData['link'];
            }
          }

          if (downloadUrl == null) {
            downloadUrl =
                songData['media_preview_url'] ??
                songData['media_url'] ??
                songData['preview_url'] ??
                songData['stream_url'];
          }
        }

        print('Final download URL: $downloadUrl');

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          if (downloadUrl.contains('preview.saavncdn.com') ||
              downloadUrl.contains('aac.saavncdn.com')) {
            print('Setting audio URL: $downloadUrl');
            await _audioPlayer.setUrl(downloadUrl);
            await _audioPlayer.play();
            // Loading will be cleared by playerStateStream listener
          } else {
            throw Exception('Invalid audio URL format');
          }
        } else {
          throw Exception('No download URL found in response');
        }
      } else {
        throw Exception('No song ID found');
      }
    } catch (e) {
      print('Error playing song: $e');
      setState(() {
        _isSongLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing song: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _playAlbum(Map<String, dynamic> album) async {
    try {
      final albumId = album['id'];
      if (albumId != null) {
        final albumDetails = await _apiService.getAlbum(id: albumId);
        final songs = albumDetails['data']?['songs'];

        if (songs != null && songs.isNotEmpty) {
          final firstSong = songs[0];
          final downloadUrl = firstSong['downloadUrl']?[0]?['link'];

          if (downloadUrl != null) {
            await _audioPlayer.setUrl(downloadUrl);
            await _audioPlayer.play();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing album: ${album['name']}'),
                backgroundColor: const Color(0xFFff7d78),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing album: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildMiniPlayer() {
    // Extract artist name properly from current song data
    String artistName = 'Unknown Artist';
    if (_currentSong?['artists'] != null) {
      final artists = _currentSong!['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        artistName = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (_currentSong?['primaryArtists'] != null) {
      artistName = _currentSong!['primaryArtists'];
    } else if (_currentSong?['subtitle'] != null) {
      artistName = _currentSong!['subtitle'];
    }

    // Get album art URL with fallback options
    String albumArtUrl = '';
    if (_currentSong?['image'] != null) {
      albumArtUrl = _getBestImageUrl(_currentSong!['image']) ?? '';
    }

    final songTitle =
        _currentSong?['name'] ?? _currentSong?['title'] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return StreamBuilder<Duration>(
                stream: _audioPlayer.positionStream,
                builder: (context, positionSnapshot) {
                  return StreamBuilder<Duration?>(
                    stream: _audioPlayer.durationStream,
                    builder: (context, durationSnapshot) {
                      return StreamBuilder<bool>(
                        stream: _audioPlayer.playingStream,
                        builder: (context, playingSnapshot) {
                          String currentSongTitle =
                              _currentSong?['name'] ??
                              _currentSong?['title'] ??
                              'Unknown';
                          String currentArtistName = 'Unknown Artist';
                          if (_currentSong?['artists'] != null) {
                            final artists = _currentSong!['artists'];
                            if (artists['primary'] != null &&
                                artists['primary'].isNotEmpty) {
                              currentArtistName =
                                  artists['primary'][0]['name'] ??
                                  'Unknown Artist';
                            }
                          } else if (_currentSong?['primaryArtists'] != null) {
                            currentArtistName = _currentSong!['primaryArtists'];
                          } else if (_currentSong?['subtitle'] != null) {
                            currentArtistName = _currentSong!['subtitle'];
                          }

                          String currentAlbumArtUrl = '';
                          if (_currentSong?['image'] != null) {
                            currentAlbumArtUrl =
                                _getBestImageUrl(_currentSong!['image']) ?? '';
                          }

                          return MusicPlayerPage(
                            songTitle: currentSongTitle,
                            artistName: currentArtistName,
                            albumArtUrl: currentAlbumArtUrl,
                            songId: _currentSong?['id'], // Add this line
                            isPlaying: playingSnapshot.data ?? false,
                            isLoading: _isSongLoading,
                            currentPosition:
                                positionSnapshot.data ?? Duration.zero,
                            totalDuration:
                                durationSnapshot.data ?? Duration.zero,
                            onPlayPause: () {
                              if (_audioPlayer.playing) {
                                _audioPlayer.pause();
                              } else {
                                _audioPlayer.play();
                              }
                            },
                            onNext: _playNextSong,
                            onPrevious: _playPreviousSong,
                            onSeek: (value) {
                              final position =
                                  (durationSnapshot.data ?? Duration.zero) *
                                  value;
                              _audioPlayer.seek(position);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.0, 1.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFff7d78).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Album Art with Hero Animation
              Hero(
                tag: 'album_art_${_currentSong?['id'] ?? 'current'}',
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFff7d78).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: albumArtUrl.isNotEmpty
                        ? Image.network(
                            albumArtUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Song Info with Hero Animation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'song_title_${_currentSong?['id'] ?? 'current'}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          songTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Hero(
                      tag: 'artist_name_${_currentSong?['id'] ?? 'current'}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          artistName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Control buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/Pause button
                  StreamBuilder<bool>(
                    stream: _audioPlayer.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return IconButton(
                        onPressed: () {
                          if (isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: const Color(0xFFff7d78),
                          size: 28,
                        ),
                        padding: const EdgeInsets.all(4),
                      );
                    },
                  ),
                  // Close button
                  IconButton(
                    onPressed: () {
                      _audioPlayer.stop();
                      setState(() {
                        _currentSong = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playNextSong() {
    if (_currentPlaylist.isNotEmpty &&
        _currentSongIndex < _currentPlaylist.length - 1) {
      _currentSongIndex++;
      // Reset audio player state immediately
      _audioPlayer.stop();
      _playSong(_currentPlaylist[_currentSongIndex]);
    }
  }

  void _playPreviousSong() {
    if (_currentPlaylist.isNotEmpty && _currentSongIndex > 0) {
      _currentSongIndex--;
      // Reset audio player state immediately
      _audioPlayer.stop();
      _playSong(_currentPlaylist[_currentSongIndex]);
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
}
