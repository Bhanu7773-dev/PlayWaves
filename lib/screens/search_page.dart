import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/jiosaavn_api_service.dart';
import '../widgets/animated_navbar.dart';
import '../widgets/mini_player.dart';
import 'music_player.dart';
import '../services/player_state_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';

class SearchPage extends StatefulWidget {
  final Function(int) onNavTap;
  final int selectedNavIndex;
  const SearchPage({
    super.key,
    required this.onNavTap,
    required this.selectedNavIndex,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late FocusNode _searchFocusNode;
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
    _searchFocusNode = FocusNode();
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _meteorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
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

    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
    audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        final playerState = Provider.of<PlayerStateProvider>(
          context,
          listen: false,
        );
        // Only update if the current song is set
        if (playerState.currentSong != null) {
          playerState.setPlaying(playing);
          setState(() {});
        }
      }
    });
    audioPlayer.playerStateStream.listen((state) {
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

      final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
      await audioPlayer.stop();
      await audioPlayer.seek(Duration.zero);

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
            await audioPlayer.setAudioSource(
              AudioSource.uri(
                Uri.parse(downloadUrl),
                tag: MediaItem(
                  id: songId ?? '',
                  album:
                      songData?['album']?['name'] ?? songData?['album'] ?? '',
                  title: songData?['title'] ?? songData?['name'] ?? '',
                  artist: (() {
                    if (songData?['artists'] != null &&
                        songData?['artists'] is Map &&
                        songData?['artists']['primary'] is List &&
                        (songData?['artists']['primary'] as List).isNotEmpty) {
                      return songData?['artists']['primary'][0]['name'] ?? '';
                    } else if (songData?['primaryArtists'] != null) {
                      final pa = songData?['primaryArtists'];
                      if (pa != null && pa.toString().isNotEmpty) {
                        return pa;
                      }
                    } else if (songData?['subtitle'] != null) {
                      final sub = songData?['subtitle'];
                      if (sub != null && sub.toString().isNotEmpty) {
                        return sub;
                      }
                    }
                    return '';
                  })(),
                  artUri: (() {
                    final imageField = songData?['image'];
                    if (imageField is List && imageField.isNotEmpty) {
                      final img = imageField.last ?? imageField.first;
                      if (img is String) {
                        return Uri.parse(img);
                      } else if (img is Map && img['url'] != null) {
                        return Uri.parse(img['url']);
                      } else if (img is Map && img['link'] != null) {
                        return Uri.parse(img['link']);
                      }
                    } else if (imageField is String) {
                      return Uri.parse(imageField);
                    }
                    return null;
                  })(),
                ),
              ),
            );
            await audioPlayer.play();
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

  Widget _buildAnimatedBackground({bool isPitchBlack = false}) {
    final customTheme = Provider.of<CustomThemeProvider>(
      context,
      listen: false,
    );
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    final secondaryColor = customTheme.secondaryColor;
    return Container(
      decoration: BoxDecoration(
        gradient: (isPitchBlack || customColorsEnabled)
            ? null
            : const RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Colors.black],
              ),
        color: isPitchBlack
            ? Colors.black
            : (customColorsEnabled ? secondaryColor : null),
      ),
      child: Stack(
        children: List.generate(
          12,
          (index) =>
              _buildMeteor(index, customColorsEnabled ? primaryColor : null),
        ),
      ),
    );
  }

  Widget _buildMeteor(int index, [Color? meteorColor]) {
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
                  colors: meteorColor != null
                      ? [
                          meteorColor.withOpacity(0.8),
                          meteorColor.withOpacity(0.3),
                          Colors.transparent,
                        ]
                      : [
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
    final customTheme = Provider.of<CustomThemeProvider>(
      context,
      listen: false,
    );
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
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
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Discover your next favorite song...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Consumer<CustomThemeProvider>(
                      builder: (context, customTheme, child) {
                        final customColorsEnabled =
                            customTheme.customColorsEnabled;
                        final primaryColor = customTheme.primaryColor;
                        if (customColorsEnabled) {
                          return Icon(
                            Icons.music_note_rounded,
                            color: primaryColor,
                            size: 24,
                          );
                        } else {
                          return ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
                onTap: () {},
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            if (_searchFocusNode.hasFocus)
              IconButton(
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
                  _searchFocusNode.unfocus();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final customTheme = Provider.of<CustomThemeProvider>(
      context,
      listen: false,
    );
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              gradient: !customColorsEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    )
                  : null,
              color: customColorsEnabled ? primaryColor : null,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
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
              gradient: !customColorsEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    )
                  : null,
              color: customColorsEnabled ? primaryColor : null,
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

    final customTheme = Provider.of<CustomThemeProvider>(
      context,
      listen: false,
    );
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;

    final playerState = Provider.of<PlayerStateProvider>(context);
    final isCurrentSong =
        playerState.currentSong != null &&
        playerState.currentSong?['id'] == song['id'];
    final isLoading = playerState.isSongLoading && isCurrentSong;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: !customColorsEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              )
            : null,
        color: customColorsEnabled ? Colors.white.withOpacity(0.05) : null,
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
          onTap: () {
            final audioPlayer = Provider.of<AudioPlayer>(
              context,
              listen: false,
            );
            final playerState = Provider.of<PlayerStateProvider>(
              context,
              listen: false,
            );

            if (isCurrentSong) {
              if (playerState.isPlaying) {
                audioPlayer.pause();
                playerState.setPlaying(false);
              } else {
                audioPlayer.play();
                playerState.setPlaying(true);
              }
            } else {
              _playSong(song, index);
            }
          },
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
                        gradient: !customColorsEnabled
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFff7d78).withOpacity(0.3),
                                  const Color(0xFF9c27b0).withOpacity(0.3),
                                ],
                              )
                            : null,
                        color: customColorsEnabled
                            ? primaryColor.withOpacity(0.3)
                            : null,
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
                                      gradient: !customColorsEnabled
                                          ? LinearGradient(
                                              colors: [
                                                const Color(
                                                  0xFFff7d78,
                                                ).withOpacity(0.3),
                                                const Color(
                                                  0xFF9c27b0,
                                                ).withOpacity(0.3),
                                              ],
                                            )
                                          : null,
                                      color: customColorsEnabled
                                          ? primaryColor.withOpacity(0.3)
                                          : null,
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
                                  gradient: !customColorsEnabled
                                      ? LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFFff7d78,
                                            ).withOpacity(0.3),
                                            const Color(
                                              0xFF9c27b0,
                                            ).withOpacity(0.3),
                                          ],
                                        )
                                      : null,
                                  color: customColorsEnabled
                                      ? primaryColor.withOpacity(0.3)
                                      : null,
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
                          gradient: !customColorsEnabled
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFff7d78),
                                    Color(0xFF9c27b0),
                                  ],
                                )
                              : null,
                          color: customColorsEnabled ? primaryColor : null,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: !customColorsEnabled
                                  ? const Color(0xFFff7d78).withOpacity(0.5)
                                  : primaryColor.withOpacity(0.5),
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
                    gradient: !customColorsEnabled
                        ? const LinearGradient(
                            colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                          )
                        : null,
                    color: customColorsEnabled ? primaryColor : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: !customColorsEnabled
                            ? const Color(0xFFff7d78).withOpacity(0.4)
                            : primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () {
                        final audioPlayer = Provider.of<AudioPlayer>(
                          context,
                          listen: false,
                        );
                        final playerState = Provider.of<PlayerStateProvider>(
                          context,
                          listen: false,
                        );

                        if (isCurrentSong) {
                          if (playerState.isPlaying) {
                            audioPlayer.pause();
                          } else {
                            audioPlayer.play();
                          }
                        } else {
                          _playSong(song, index);
                        }
                      },
                      child: isLoading
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 37,
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
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    final secondaryColor = customTheme.secondaryColor;

    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : secondaryColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(isPitchBlack: isPitchBlack),

          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.transparent),
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
                        width: 42,
                        height: 42,
                        child: Icon(Icons.search, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            (!customColorsEnabled && !isPitchBlack)
                                ? ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFFff7d78),
                                            Color(0xFF9c27b0),
                                          ],
                                        ).createShader(bounds),
                                    child: const Text(
                                      'Discover Music',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Discover Music',
                                    style: TextStyle(
                                      color: customColorsEnabled
                                          ? primaryColor
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
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

                _buildEnhancedSearchBar(),

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
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRandomSongs,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFff7d78),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Try Again'),
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
                                Icons.music_note,
                                color: Colors.grey[400],
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.trim().isEmpty
                                    ? 'No trending songs found'
                                    : 'No results found',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.trim().isEmpty
                                    ? 'Try searching for your favorite music'
                                    : 'Try different keywords',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: customColorsEnabled
                                          ? primaryColor
                                          : null,
                                      gradient: !customColorsEnabled
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFFff7d78),
                                                Color(0xFF9c27b0),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _searchController.text.trim().isEmpty
                                        ? 'Trending Songs'
                                        : 'Search Results',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                itemCount: songsToShow.length,
                                itemBuilder: (context, index) {
                                  final song = songsToShow[index];
                                  return _buildEnhancedSongTile(song, index);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // ...existing code...
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    _meteorController.dispose();
    _searchController2.dispose();
    super.dispose();
  }
}
