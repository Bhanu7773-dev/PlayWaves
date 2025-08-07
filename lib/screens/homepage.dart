import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../services/jiosaavn_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final JioSaavnApiService _apiService = JioSaavnApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _bannerController = PageController();

  List<Map<String, dynamic>> _trendingSongs = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _bannerSongs = [];
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    _startBannerAutoScroll();
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

      final songsResponse = await _apiService.searchSongs(
        'arijit singh',
        limit: 10,
      );
      final albumsResponse = await _apiService.searchAlbums(
        'arijit singh',
        limit: 5,
      );
      final bannerResponse = await _apiService.searchSongs(
        'trending hindi songs',
        limit: 6,
      );

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

      if (bannerResponse['success'] == true && bannerResponse['data'] != null) {
        final bannerData = bannerResponse['data'];
        if (bannerData['results'] != null) {
          final banners = List<Map<String, dynamic>>.from(
            bannerData['results'],
          );
          setState(() {
            _bannerSongs = banners;
          });
        }
      }

      setState(() {
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
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                  ),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ).createShader(bounds),
                child: const Text(
                  'Play Waves',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Settings action
            },
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFff7d78)),
            ),
            SizedBox(height: 16),
            Text('Loading music...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFff7d78),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFff7d78),
      backgroundColor: Colors.black,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              if (_trendingSongs.isNotEmpty) _buildSongsSection(),
            ],
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFff7d78).withOpacity(0.3),
            const Color(0xFF9c27b0).withOpacity(0.3),
          ],
        ),
      ),
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
            right: 80,
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
                const SizedBox(height: 4),
                Text(
                  artist,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
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
          height: 220,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFff7d78).withOpacity(0.3),
                                  const Color(0xFF9c27b0).withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.album,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFff7d78).withOpacity(0.3),
                            const Color(0xFF9c27b0).withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.album, color: Colors.white, size: 50),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      final songId = song['id'];
      if (songId != null) {
        final songDetails = await _apiService.getSongById(songId);
        final downloadUrl =
            songDetails['data']?[0]?['downloadUrl']?[0]?['link'];

        if (downloadUrl != null) {
          await _audioPlayer.setUrl(downloadUrl);
          await _audioPlayer.play();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing: ${song['name']}'),
              backgroundColor: const Color(0xFFff7d78),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing song: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
}
