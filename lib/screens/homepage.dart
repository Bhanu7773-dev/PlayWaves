import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/jiosaavn_api_service.dart';
import '../widgets/animated_navbar.dart';
import '../widgets/mini_player.dart';
import 'music_player.dart';
import 'search_page.dart';
import '../services/player_state_provider.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// Helper function: pick N random (non-repeating) songs from a list, skipping recently shown
Future<Set<String>> loadShownIdsFromStorage() async {
  // TODO: Implement persistent storage (SharedPreferences/Hive etc.)
  // For now, just return an empty set.
  return <String>{};
}

Future<void> saveShownIdsToStorage(Set<String> ids) async {
  // TODO: Implement persistent storage
}

List<Map<String, dynamic>> getUnseenRandomSongs(
  List<Map<String, dynamic>> songsList,
  int count,
  Set<String> shownSongIds,
) {
  final unseen = songsList
      .where((song) => !shownSongIds.contains(song['id']))
      .toList();
  unseen.shuffle(Random());
  final selected = unseen.take(count).toList();
  shownSongIds.addAll(selected.map((s) => s['id']));
  return selected;
}

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

  List<Map<String, dynamic>> _trendingSongs = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _bannerSongs = [];
  List<Map<String, dynamic>> _randomSongs = [];

  bool _isLoading = true;
  String? _error;

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

    // Listen to audio player state and update provider accordingly
    _audioPlayer.playingStream.listen((playing) {
      final playerState = Provider.of<PlayerStateProvider>(
        context,
        listen: false,
      );
      playerState.setPlaying(playing);
      if (playing) {
        playerState.setSongLoading(false);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      final playerState = Provider.of<PlayerStateProvider>(
        context,
        listen: false,
      );
      if (state.processingState == ProcessingState.ready) {
        playerState.setSongLoading(false);
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
        'top hits',
        'billboard top',
        'viral songs',
        'spotify viral',
        'youtube trending',
        'folk music',
        'old hindi songs',
        'retro hits',
        'dance hits',
        'chill music',
        'instrumental hits',
        'workout songs',
        'study music',
        '90s hits',
        '2000s hits',
        'international hits',
        'regional hits',
        'desi pop',
        'love songs',
        'sad songs',
        'happy songs',
        'motivational songs',
        'indian rap',
        'ghazals',
        'sufi music',
        'devotional songs',
        'wedding songs',
        'festival songs',
        'summer hits',
        'winter hits',
        'road trip songs',
        'kids songs',
        'bollywood remixes',
        'cover songs',
        'mashup songs',
        'melancholic music',
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
        'international albums',
        'regional albums',
        'indie albums',
        'remix albums',
        'soundtrack albums',
        'compilation albums',
        'award winning albums',
        'top albums',
        'classical albums',
        'romantic albums',
        'party albums',
        'folk albums',
        'devotional albums',
        'ghazal albums',
        'sufi albums',
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
        'featured bollywood',
        'editor picks',
        'top charts',
        'playlist favorites',
        'international top charts',
        'festival special',
        'new music friday',
        'weekly top 20',
        'hot 100',
        'ultimate party mix',
        'best of 2023',
        'on repeat',
        'radio hits',
        'summer vibes',
        'winter anthems',
        'road trip playlist',
        'club bangers',
        'bollywood superhits',
      ];

      final random = Random();
      final songQuery = songQueries[random.nextInt(songQueries.length)];
      final albumQuery = albumQueries[random.nextInt(albumQueries.length)];
      final bannerQuery = bannerQueries[random.nextInt(bannerQueries.length)];

      // Fetch trending songs
      final songsResponse = await _apiService.searchSongs(songQuery, limit: 18);
      final albumsResponse = await _apiService.searchAlbums(
        albumQuery,
        limit: 5,
      );
      final bannerResponse = await _apiService.searchSongs(
        bannerQuery,
        limit: 5,
      );

      // Fetch random songs from multiple queries for true randomness and non-repeat
      Set<String> shownSongIds = await loadShownIdsFromStorage();
      List<Map<String, dynamic>> allSongs = [];
      final shuffledQueries = List<String>.from(songQueries)..shuffle();
      for (var q in shuffledQueries) {
        final response = await _apiService.searchSongs(q, limit: 12);
        if (response['success'] == true && response['data'] != null) {
          final songs = List<Map<String, dynamic>>.from(
            response['data']['results'] ?? [],
          );
          allSongs.addAll(songs);
        }
      }
      // Remove duplicates by song ID
      final uniqueSongs = {for (var s in allSongs) s['id']: s}.values.toList();
      final randomSongs = getUnseenRandomSongs(uniqueSongs, 12, shownSongIds);
      await saveShownIdsToStorage(shownSongIds);

      // Artists logic
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
      List<Map<String, dynamic>> allArtists = [];
      final shuffledArtists = List<String>.from(famousArtists)..shuffle();
      for (int i = 0; i < 6 && i < shuffledArtists.length; i++) {
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

      // Trending songs, albums, banners
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
      List<Map<String, dynamic>> bannerSongs = [];
      try {
        // Use random banner query instead of fixed "trending songs"
        final bannerSongsResponse = await _apiService.searchSongs(
          bannerQuery,
          limit: 6,
        );
        if (bannerSongsResponse['success'] == true &&
            bannerSongsResponse['data'] != null) {
          final bannerData = bannerSongsResponse['data'];
          if (bannerData['results'] != null) {
            final banners = List<Map<String, dynamic>>.from(
              bannerData['results'],
            );
            bannerSongs.addAll(banners);
          }
        }

        // If we don't have enough banners, add from a different random query
        if (bannerSongs.length < 5) {
          final fallbackQuery =
              bannerQueries[random.nextInt(bannerQueries.length)];
          final fallbackResponse = await _apiService.searchSongs(
            fallbackQuery,
            limit: 5,
          );
          if (fallbackResponse['success'] == true &&
              fallbackResponse['data'] != null) {
            final fallbackData = fallbackResponse['data'];
            if (fallbackData['results'] != null) {
              final fallbackBanners = List<Map<String, dynamic>>.from(
                fallbackData['results'],
              );
              bannerSongs.addAll(fallbackBanners);
            }
          }
        }

        // Remove duplicates and limit to 5
        final uniqueBanners = {
          for (var s in bannerSongs) s['id']: s,
        }.values.toList();
        bannerSongs = uniqueBanners.take(5).toList();
      } catch (e) {
        print('Banner query failed: $e');
        // Fallback to test song only if everything fails
      }

      setState(() {
        _bannerSongs = bannerSongs;
        _artists = allArtists;
        _randomSongs = randomSongs;
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
    final playerState = Provider.of<PlayerStateProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          if (playerState.currentSong != null)
            Positioned(
              bottom: 70,
              left: 16,
              right: 16,
              child: MiniPlayer(
                currentSong: playerState.currentSong,
                audioPlayer: _audioPlayer,
                isSongLoading: playerState.isSongLoading,
                onPlayPause: () {
                  if (_audioPlayer.playing) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
                onClose: () {
                  _audioPlayer.stop();
                  playerState.clearSong();
                },
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        final song = playerState.currentSong;
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
                                        song?['name'] ??
                                        song?['title'] ??
                                        'Unknown';
                                    String currentArtistName = 'Unknown Artist';
                                    if (song?['artists'] != null) {
                                      final artists = song!['artists'];
                                      if (artists['primary'] != null &&
                                          artists['primary'].isNotEmpty) {
                                        currentArtistName =
                                            artists['primary'][0]['name'] ??
                                            'Unknown Artist';
                                      }
                                    } else if (song?['primaryArtists'] !=
                                        null) {
                                      currentArtistName =
                                          song!['primaryArtists'];
                                    } else if (song?['subtitle'] != null) {
                                      currentArtistName = song!['subtitle'];
                                    }
                                    String? currentAlbumArtUrl = '';
                                    if (song?['image'] != null) {
                                      currentAlbumArtUrl = _getBestImageUrl(
                                        song!['image'],
                                      );
                                    }
                                    return MusicPlayerPage(
                                      songTitle: currentSongTitle,
                                      artistName: currentArtistName,
                                      albumArtUrl: currentAlbumArtUrl ?? '',
                                      songId: song?['id'],
                                      isPlaying: playingSnapshot.data ?? false,
                                      isLoading: playerState.isSongLoading,
                                      currentPosition:
                                          positionSnapshot.data ??
                                          Duration.zero,
                                      totalDuration:
                                          durationSnapshot.data ??
                                          Duration.zero,
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
                                            (durationSnapshot.data ??
                                                Duration.zero) *
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
              ),
            ),
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
        break;
      case 1:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SearchPage(
              onNavTap: _onNavTap,
              selectedNavIndex: _selectedNavIndex,
              audioPlayer: _audioPlayer,
              onPlayPause: () {
                if (_audioPlayer.playing) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
              onNext: _playNextSong,
              onPrevious: _playPreviousSong,
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
        break;
      case 3:
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
            padding: const EdgeInsets.only(bottom: 100),
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
                if (_randomSongs.isNotEmpty) _buildRandomSongsSection(),
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
                    onPressed: () => _playSong(song, null, false),
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
    final name = artist['name'] ?? 'Unknown Artist';

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFff7d78).withOpacity(0.3),
                  const Color(0xFF9c27b0).withOpacity(0.3),
                ],
              ),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        );
                      },
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRandomSongsSection() {
    List<SwipeItem> _swipeItems = [];
    MatchEngine _matchEngine;

    // Fill swipe items with songs
    for (var i = 0; i < _randomSongs.length; i++) {
      final song = _randomSongs[i];
      _swipeItems.add(
        SwipeItem(
          content: song,
          likeAction: () {},
          nopeAction: () {},
          superlikeAction: () {},
        ),
      );
    }
    _matchEngine = MatchEngine(swipeItems: _swipeItems);

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
                "Random Picks",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_randomSongs.isNotEmpty)
          SizedBox(
            height: 360,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SwipeCards(
                  matchEngine: _matchEngine,
                  itemBuilder: (context, index) {
                    final song = _randomSongs[index];
                    final imageUrl = _getBestImageUrl(song['image']);
                    final title =
                        song['name'] ?? song['title'] ?? 'Unknown Song';
                    final artist =
                        song['artists']?['primary']?[0]?['name'] ??
                        song['subtitle'] ??
                        'Unknown Artist';
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      color: const Color.fromARGB(
                        255,
                        17,
                        17,
                        17,
                      ).withOpacity(1.0),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(22),
                                ),
                                child: imageUrl != null
                                    ? Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: double.infinity,
                                          height: 180,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.white54,
                                            size: 48,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: double.infinity,
                                        height: 180,
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white54,
                                          size: 48,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      artist,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFff7d78),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        _playSong(song, index, true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Magic text overlay
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.84),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Swipe to see magic!",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onStackFinished: () {
                    // Restart the stack from the beginning!
                    Future.delayed(const Duration(milliseconds: 400), () {
                      setState(() {
                        _swipeItems.clear();
                        for (var i = 0; i < _randomSongs.length; i++) {
                          final song = _randomSongs[i];
                          _swipeItems.add(
                            SwipeItem(
                              content: song,
                              likeAction: () {},
                              nopeAction: () {},
                              superlikeAction: () {},
                            ),
                          );
                        }
                        _matchEngine = MatchEngine(swipeItems: _swipeItems);
                      });
                    });
                  },
                  upSwipeAllowed: false,
                  fillSpace: true,
                );
              },
            ),
          ),
        if (_randomSongs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                "No random songs available",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
      ],
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
        MasonryGridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: _trendingSongs.length,
          itemBuilder: (context, index) {
            final song = _trendingSongs[index];
            return _buildMasonrySongCard(song, index);
          },
        ),
      ],
    );
  }

  Widget _buildMasonrySongCard(Map<String, dynamic> song, int index) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    String artist = 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        artist = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['subtitle'] != null) {
      artist = song['subtitle'];
    }

    return GestureDetector(
      onTap: () => _playSong(song, index, false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(Map<String, dynamic> song, int index, bool useRandom) {
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
            onPressed: () => _playSong(song, index, useRandom),
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

  Future<void> _playSong(
    Map<String, dynamic> song,
    int? index,
    bool useRandom,
  ) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    try {
      playerState.setSongLoading(true);
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);

      // Pick playlist: trending or random
      final playlist = useRandom
          ? List<Map<String, dynamic>>.from(_randomSongs)
          : List<Map<String, dynamic>>.from(_trendingSongs);

      playerState.setPlaylist(playlist);

      if (index != null) {
        playerState.setSongIndex(index);
      } else {
        final songIndex = playlist.indexWhere((s) => s['id'] == song['id']);
        playerState.setSongIndex(songIndex == -1 ? 0 : songIndex);
      }

      playerState.setSong(Map<String, dynamic>.from(song));

      final songId = song['id'];
      if (songId != null) {
        final songDetails = await _apiService.getSongById(songId);
        String? downloadUrl;
        final songData = songDetails['data']?[0];

        if (songData != null) {
          playerState.setSong(Map<String, dynamic>.from(songData));
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

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          if (downloadUrl.contains('preview.saavncdn.com') ||
              downloadUrl.contains('aac.saavncdn.com')) {
            await _audioPlayer.setUrl(downloadUrl);
            await _audioPlayer.play();
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
      playerState.setSongLoading(false);
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
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    try {
      playerState.setSongLoading(true);
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);

      final albumId = album['id'];
      if (albumId != null) {
        final albumDetails = await _apiService.getAlbum(id: albumId);
        final songs = albumDetails['data']?['songs'];
        if (songs != null && songs.isNotEmpty) {
          final albumSongs = List<Map<String, dynamic>>.from(songs);
          final firstSong = albumSongs[0];

          // Set up playlist and player state
          playerState.setPlaylist(albumSongs);
          playerState.setSongIndex(0);
          playerState.setSong(Map<String, dynamic>.from(firstSong));

          // Get song details and play
          final songId = firstSong['id'];
          if (songId != null) {
            final songDetails = await _apiService.getSongById(songId);
            String? downloadUrl;
            final songData = songDetails['data']?[0];

            if (songData != null) {
              playerState.setSong(Map<String, dynamic>.from(songData));
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

            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              if (downloadUrl.contains('preview.saavncdn.com') ||
                  downloadUrl.contains('aac.saavncdn.com')) {
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
              } else {
                throw Exception('Invalid audio URL format');
              }
            } else {
              throw Exception('No download URL found');
            }
          } else {
            throw Exception('No song ID found');
          }
        } else {
          throw Exception('No songs found in album');
        }
      } else {
        throw Exception('No album ID found');
      }
    } catch (e) {
      playerState.setSongLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing album: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _playNextSong() {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final playlist = playerState.currentPlaylist;
    final songIndex = playerState.currentSongIndex;
    if (playlist.isNotEmpty && songIndex < playlist.length - 1) {
      final nextSong = playlist[songIndex + 1];
      bool useRandom = ListEquality().equals(playlist, _randomSongs);
      _playSong(nextSong, songIndex + 1, useRandom);
    }
  }

  void _playPreviousSong() {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final playlist = playerState.currentPlaylist;
    final songIndex = playerState.currentSongIndex;
    if (playlist.isNotEmpty && songIndex > 0) {
      final prevSong = playlist[songIndex - 1];
      bool useRandom = ListEquality().equals(playlist, _randomSongs);
      _playSong(prevSong, songIndex - 1, useRandom);
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

// For deep equality of lists
class ListEquality {
  bool equals(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id']) return false;
    }
    return true;
  }
}
