import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/jiosaavn_api_service.dart';
import '../widgets/animated_navbar.dart';
import 'music_player.dart';

class SearchPage extends StatefulWidget {
  final Function(int) onNavTap;
  final int selectedNavIndex;
  final Map<String, dynamic>? currentSong;
  final AudioPlayer audioPlayer;
  final bool isSongLoading;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Function(Map<String, dynamic>) onSongChanged;

  const SearchPage({
    super.key,
    required this.onNavTap,
    required this.selectedNavIndex,
    this.currentSong,
    required this.audioPlayer,
    required this.isSongLoading,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSongChanged,
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadRandomSongs();
    _setupSearchListener();
    _animationController.forward();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (!mounted) return; // Add mounted check
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
    if (!mounted) return; // Add mounted check
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final queries = [
        'trending hindi songs',
        'bollywood hits',
        'punjabi songs',
        'english hits',
        'romantic songs',
      ];
      final randomQuery =
          queries[DateTime.now().millisecondsSinceEpoch % queries.length];
      final response = await _apiService.searchSongs(randomQuery, limit: 20);

      if (!mounted) return; // Add mounted check before setState

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data['results'] != null) {
          setState(() {
            _randomSongs = List<Map<String, dynamic>>.from(data['results']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Add mounted check
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2 || !mounted) return; // Add mounted check
    setState(() {
      _isSearching = true;
    });
    try {
      final response = await _apiService.searchSongs(query, limit: 15);

      if (!mounted) return; // Add mounted check before setState

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data['results'] != null) {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(data['results']);
            _isSearching = false;
          });
        } else {
          setState(() {
            _isSearching = false;
          });
        }
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Add mounted check
      setState(() {
        _isSearching = false;
      });
    }
  }

  String _getBestImageUrl(dynamic images) {
    if (images == null) return '';
    if (images is List && images.isNotEmpty) {
      for (var image in images.reversed) {
        if (image['quality'] == '500x500' || image['quality'] == '150x150') {
          return image['link'] ?? image['url'] ?? '';
        }
      }
      return images.last['link'] ?? images.last['url'] ?? '';
    }
    return '';
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    if (!mounted) return; // Add mounted check
    try {
      final songId = song['id'];
      if (songId == null) return;

      await widget.audioPlayer.stop();
      await widget.audioPlayer.setVolume(1.0);

      // Update parent's current song immediately
      widget.onSongChanged(song);

      final response = await _apiService.getSongById(songId);

      if (!mounted) return; // Add mounted check before navigation

      if (response['success'] == true && response['data'] != null) {
        final songData = response['data'][0];
        String? downloadUrl;
        if (songData['downloadUrl'] != null) {
          if (songData['downloadUrl'] is List &&
              songData['downloadUrl'].isNotEmpty) {
            downloadUrl =
                songData['downloadUrl'].last['url'] ??
                songData['downloadUrl'].last['link'];
          } else if (songData['downloadUrl'] is String) {
            downloadUrl = songData['downloadUrl'];
          }
        }
        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          await widget.audioPlayer.setUrl(downloadUrl);
          await widget.audioPlayer.play();

          // Navigate to music player
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MusicPlayerPage(
                  songTitle: song['name'] ?? 'Unknown',
                  artistName: _getArtistName(song),
                  albumArtUrl: _getBestImageUrl(song['image']),
                  songId: songId,
                  isPlaying: true,
                  isLoading: false,
                  currentPosition: Duration.zero,
                  totalDuration: Duration.zero,
                  onPlayPause: () {
                    if (widget.audioPlayer.playing) {
                      widget.audioPlayer.pause();
                    } else {
                      widget.audioPlayer.play();
                    }
                  },
                  onNext: widget.onNext,
                  onPrevious: widget.onPrevious,
                  onSeek: (value) {
                    final position =
                        (widget.audioPlayer.duration ?? Duration.zero) * value;
                    widget.audioPlayer.seek(position);
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('No valid download URL found');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play song: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getArtistName(Map<String, dynamic> song) {
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        return artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    }
    return song['subtitle'] ?? 'Unknown Artist';
  }

  Widget _buildSongTile(Map<String, dynamic> song) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? 'Unknown Song';
    final artist = _getArtistName(song);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white),
                    );
                  },
                )
              : Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          artist,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          ),
          onPressed: () => _playSong(song),
        ),
        onTap: () => _playSong(song),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    if (widget.currentSong == null) return const SizedBox.shrink();

    String currentSongTitle =
        widget.currentSong?['name'] ??
        widget.currentSong?['title'] ??
        'Unknown';
    String currentArtistName = 'Unknown Artist';

    if (widget.currentSong?['artists'] != null) {
      final artists = widget.currentSong!['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        currentArtistName = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (widget.currentSong?['subtitle'] != null) {
      currentArtistName = widget.currentSong!['subtitle'];
    }

    String currentAlbumArtUrl = '';
    if (widget.currentSong?['image'] != null) {
      currentAlbumArtUrl = _getBestImageUrl(widget.currentSong!['image']);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return StreamBuilder<Duration>(
                stream: widget.audioPlayer.positionStream,
                builder: (context, positionSnapshot) {
                  return StreamBuilder<Duration?>(
                    stream: widget.audioPlayer.durationStream,
                    builder: (context, durationSnapshot) {
                      return StreamBuilder<bool>(
                        stream: widget.audioPlayer.playingStream,
                        builder: (context, playingSnapshot) {
                          return MusicPlayerPage(
                            songTitle: currentSongTitle,
                            artistName: currentArtistName,
                            albumArtUrl: currentAlbumArtUrl,
                            songId: widget.currentSong?['id'],
                            isPlaying: playingSnapshot.data ?? false,
                            isLoading: widget.isSongLoading,
                            currentPosition:
                                positionSnapshot.data ?? Duration.zero,
                            totalDuration:
                                durationSnapshot.data ?? Duration.zero,
                            onPlayPause: widget.onPlayPause,
                            onNext: widget.onNext,
                            onPrevious: widget.onPrevious,
                            onSeek: (value) {
                              final position =
                                  (durationSnapshot.data ?? Duration.zero) *
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
              // Album Art
              Container(
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
                  child: currentAlbumArtUrl.isNotEmpty
                      ? Image.network(
                          currentAlbumArtUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFff7d78),
                                    Color(0xFF9c27b0),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentSongTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentArtistName,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Control buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<bool>(
                    stream: widget.audioPlayer.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return IconButton(
                        onPressed: widget.onPlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: const Color(0xFFff7d78),
                          size: 28,
                        ),
                        padding: const EdgeInsets.all(4),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      // Navigate back to home with slide transition
      Navigator.pop(context);
    } else {
      // Call the parent's nav tap function for other indices
      widget.onNavTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final songsToShow = _searchController.text.trim().isEmpty
        ? _randomSongs
        : _searchResults;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Search Music',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Search content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search songs, artists, albums...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[500],
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey[500],
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),

                        // Loading indicator for search
                        if (_isSearching)
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: const CircularProgressIndicator(
                              color: Color(0xFFff7d78),
                            ),
                          ),

                        // Results header
                        if (songsToShow.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _searchController.text.trim().isEmpty
                                      ? 'Trending Songs'
                                      : 'Search Results',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${songsToShow.length} songs',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Songs List
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFff7d78),
                                  ),
                                )
                              : _error.isNotEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.grey[400],
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Something went wrong',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: _loadRandomSongs,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFff7d78,
                                          ),
                                        ),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : songsToShow.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        color: Colors.grey[400],
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.trim().isEmpty
                                            ? 'No songs available'
                                            : 'No results found',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(
                                    bottom: 160,
                                  ), // Space for mini player + nav bar
                                  itemCount: songsToShow.length,
                                  itemBuilder: (context, index) {
                                    return _buildSongTile(songsToShow[index]);
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
          if (widget.currentSong != null)
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
    // Remove listener before disposing
    _searchController.removeListener(() {});
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
