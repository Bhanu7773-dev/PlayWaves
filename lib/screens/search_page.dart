import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/jiosaavn_api_service.dart';
import '../widgets/animated_navbar.dart';
import '../widgets/mini_player.dart';
import 'music_player.dart';
import '../services/player_state_provider.dart';

class SearchPage extends StatefulWidget {
  final Function(int) onNavTap;
  final int selectedNavIndex;
  final AudioPlayer audioPlayer;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const SearchPage({
    super.key,
    required this.onNavTap,
    required this.selectedNavIndex,
    required this.audioPlayer,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final JioSaavnApiService _apiService = JioSaavnApiService();

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _randomSongs = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _error = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _meteorController;
  late AnimationController _searchController2;
  late Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Meteor animation controller
    _meteorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Search bar animation controller
    _searchController2 = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchController2, curve: Curves.elasticOut),
    );

    _loadRandomSongs();
    _setupSearchListener();
    _animationController.forward();
    _searchController2.forward();

    widget.audioPlayer.playingStream.listen((playing) {
      if (mounted) setState(() {});
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() {});
    });
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (!mounted) return;
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } else {
        _performSearch(query);
      }
    });
  }

  Future<void> _loadRandomSongs() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final List<String> queries = [
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
      final random = DateTime.now().millisecondsSinceEpoch;
      final songQuery = queries[random % queries.length];
      final response = await _apiService.searchSongs(songQuery, limit: 20);

      if (response['success'] == true && response['data'] != null) {
        final songsData = response['data'];
        if (songsData['results'] != null) {
          final songs = List<Map<String, dynamic>>.from(songsData['results']);
          setState(() {
            _randomSongs = songs;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'No data found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _error = '';
    });

    try {
      final response = await _apiService.searchSongs(query, limit: 12);

      if (response['success'] == true && response['data'] != null) {
        final songsData = response['data'];
        if (songsData['results'] != null) {
          final songs = List<Map<String, dynamic>>.from(songsData['results']);
          setState(() {
            _searchResults = songs;
            _isSearching = false;
          });
        }
      } else {
        setState(() {
          _searchResults = [];
          _error = 'No results found.';
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  String _getBestImageUrl(dynamic images) {
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
    return '';
  }

  Future<void> _playSong(Map<String, dynamic> song, [int? index]) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    try {
      playerState.setSongLoading(true);

      await widget.audioPlayer.stop();
      await widget.audioPlayer.seek(Duration.zero);

      // Choose which list to use as playlist
      final songsToShow = _searchController.text.trim().isEmpty
          ? _randomSongs
          : _searchResults;
      playerState.setPlaylist(songsToShow);

      // Set song index in provider
      if (index != null) {
        playerState.setSongIndex(index);
      } else {
        final songIndex = songsToShow.indexWhere((s) => s['id'] == song['id']);
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
            await widget.audioPlayer.setUrl(downloadUrl);
            await widget.audioPlayer.play();
            playerState.setPlaying(true);
            playerState.setSongLoading(false);
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

  String _getArtistName(Map<String, dynamic> song) {
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        return artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['subtitle'] != null) {
      return song['subtitle'];
    }
    return 'Unknown Artist';
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
      child: Stack(children: List.generate(12, (index) => _buildMeteor(index))),
    );
  }

  Widget _buildMeteor(int index) {
    return AnimatedBuilder(
      animation: _meteorController,
      builder: (context, child) {
        final offset = _meteorController.value * 2 - 1;
        return Positioned(
          top:
              (index * 60.0 + offset * 100) %
              MediaQuery.of(context).size.height,
          left: (index * 90.0) % MediaQuery.of(context).size.width,
          child: Transform.rotate(
            angle: 3.14159 * 1.2,
            child: Container(
              width: 2,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSearchBar() {
    return ScaleTransition(
      scale: _searchAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFff7d78).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Discover your next favorite song...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.clear_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count tracks',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSongTile(Map<String, dynamic> song, int index) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    final artist = _getArtistName(song);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _playSong(song, index),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Track Number & Image
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFff7d78).withOpacity(0.3),
                            const Color(0xFF9c27b0).withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFFff7d78,
                                          ).withOpacity(0.3),
                                          const Color(
                                            0xFF9c27b0,
                                          ).withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  );
                                },
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
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: -2,
                      left: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFff7d78).withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
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
                const SizedBox(width: 16),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: Colors.grey[400],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artist,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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

                // Play Button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFff7d78).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => _playSong(song, index),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFff7d78).withOpacity(0.2),
                  const Color(0xFF9c27b0).withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFff7d78).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: onRetry,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else {
      widget.onNavTap(index);
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
      _playSong(nextSong, songIndex + 1);
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
      _playSong(prevSong, songIndex - 1);
    }
  }

  void _jumpToSongAtIndex(int index) {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final playlist = playerState.currentPlaylist;
    if (playlist.isNotEmpty && index >= 0 && index < playlist.length) {
      final song = playlist[index];
      _playSong(song, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<PlayerStateProvider>(context);
    final songsToShow = _searchController.text.trim().isEmpty
        ? _randomSongs
        : _searchResults;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // Enhanced Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                              ).createShader(bounds),
                              child: const Text(
                                'Search & Discover',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Text(
                              'Find your perfect soundtrack',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Enhanced Search Bar
                _buildEnhancedSearchBar(),

                // Search Loading Indicator
                if (_isSearching)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFFff7d78),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Searching for music...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content Area
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _isLoading
                        ? _buildEmptyState(
                            icon: Icons.music_note_outlined,
                            title: 'Loading Music',
                            subtitle: 'Preparing your music collection...',
                          )
                        : _error.isNotEmpty
                        ? _buildEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Oops! Something went wrong',
                            subtitle:
                                'We couldn\'t load the music.\nPlease try again.',
                            onRetry: _loadRandomSongs,
                          )
                        : songsToShow.isEmpty
                        ? _buildEmptyState(
                            icon: _searchController.text.trim().isEmpty
                                ? Icons.music_off_rounded
                                : Icons.search_off_rounded,
                            title: _searchController.text.trim().isEmpty
                                ? 'No Music Available'
                                : 'No Results Found',
                            subtitle: _searchController.text.trim().isEmpty
                                ? 'Check your connection and try again'
                                : 'Try searching with different keywords',
                          )
                        : Column(
                            children: [
                              // Section Header
                              _buildSectionHeader(
                                _searchController.text.trim().isEmpty
                                    ? 'Trending Now'
                                    : 'Search Results',
                                songsToShow.length,
                              ),

                              // Songs List
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 160),
                                  itemCount: songsToShow.length,
                                  itemBuilder: (context, index) {
                                    return _buildEnhancedSongTile(
                                      songsToShow[index],
                                      index,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Mini Music Player (when song is loaded)
          if (playerState.currentSong != null)
            Positioned(
              bottom: 70,
              left: 16,
              right: 16,
              child: MiniPlayer(
                currentSong: playerState.currentSong,
                audioPlayer: widget.audioPlayer,
                isSongLoading: playerState.isSongLoading,
                onPlayPause: widget.onPlayPause,
                onClose: () {
                  widget.audioPlayer.stop();
                  playerState.clearSong();
                },
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        final song = playerState.currentSong;
                        return StreamBuilder<Duration>(
                          stream: widget.audioPlayer.positionStream,
                          builder: (context, positionSnapshot) {
                            return StreamBuilder<Duration?>(
                              stream: widget.audioPlayer.durationStream,
                              builder: (context, durationSnapshot) {
                                return StreamBuilder<bool>(
                                  stream: widget.audioPlayer.playingStream,
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

                                    String currentAlbumArtUrl = '';
                                    if (song?['image'] != null) {
                                      currentAlbumArtUrl = _getBestImageUrl(
                                        song!['image'],
                                      );
                                    }

                                    return MusicPlayerPage(
                                      songTitle: currentSongTitle,
                                      artistName: currentArtistName,
                                      albumArtUrl: currentAlbumArtUrl,
                                      songId: song?['id'],
                                      isPlaying: playingSnapshot.data ?? false,
                                      isLoading: playerState.isSongLoading,
                                      currentPosition:
                                          positionSnapshot.data ??
                                          Duration.zero,
                                      totalDuration:
                                          durationSnapshot.data ??
                                          Duration.zero,
                                      onPlayPause: widget.onPlayPause,
                                      onNext: _playNextSong,
                                      onPrevious: _playPreviousSong,
                                      onJumpToSong: (index) =>
                                          _jumpToSongAtIndex(index),
                                      onSeek: (value) {
                                        final position =
                                            (durationSnapshot.data ??
                                                Duration.zero) *
                                            value;
                                        widget.audioPlayer.seek(position);
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

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedNavBar(
              selectedIndex: widget.selectedNavIndex,
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

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    _animationController.dispose();
    _meteorController.dispose();
    _searchController2.dispose();
    super.dispose();
  }
}
