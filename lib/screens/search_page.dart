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
      final response = await _apiService.searchSongs(songQuery, limit: 10);

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

  Widget _buildSongTile(Map<String, dynamic> song, int index) {
    final imageUrl = _getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    final artist = _getArtistName(song);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white),
                    );
                  },
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[800],
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
          style: const TextStyle(color: Colors.white70, fontSize: 14),
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
            onPressed: () => _playSong(song, index),
          ),
        ),
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
          SafeArea(
            child: Column(
              children: [
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
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
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
                        if (_isSearching)
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: const CircularProgressIndicator(
                              color: Color(0xFFff7d78),
                            ),
                          ),
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
                                  padding: const EdgeInsets.only(bottom: 160),
                                  itemCount: songsToShow.length,
                                  itemBuilder: (context, index) {
                                    return _buildSongTile(
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
    super.dispose();
  }
}
