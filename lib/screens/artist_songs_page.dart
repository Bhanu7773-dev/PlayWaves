import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../services/jiosaavn_api_service.dart';
import '../services/player_state_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';
import 'package:audio_service/audio_service.dart';
import '../screens/music_player.dart';

import 'dart:ui';

class ArtistSongsPage extends StatefulWidget {
  final String artistName;
  final JioSaavnApiService apiService;

  const ArtistSongsPage({
    Key? key,
    required this.artistName,
    required this.apiService,
  }) : super(key: key);

  @override
  State<ArtistSongsPage> createState() => _ArtistSongsPageState();
}

class _ArtistSongsPageState extends State<ArtistSongsPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _songs = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
      final playerState = Provider.of<PlayerStateProvider>(
        context,
        listen: false,
      );
      // Listen to playing state
      audioPlayer.playingStream.listen((playing) {
        if (!_isDisposed && mounted) {
          playerState.setPlaying(playing);
        }
      });
      // Listen to current index changes to update current song
      audioPlayer.currentIndexStream.listen((index) {
        if (!_isDisposed &&
            mounted &&
            index != null &&
            index >= 0 &&
            index < _songs.length) {
          playerState.setSongIndex(index);
          playerState.setSong(_songs[index]);
        }
      });
    });

    _searchArtistSongs();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncPlayerState();
    }
  }

  void _syncPlayerState() {
    if (!_isDisposed && mounted) {
      final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
      final playerState = Provider.of<PlayerStateProvider>(
        context,
        listen: false,
      );
      final actuallyPlaying = audioPlayer.playing;
      playerState.setPlaying(actuallyPlaying);

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _searchArtistSongs() async {
    if (_isDisposed) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await widget.apiService.searchSongs(
        widget.artistName,
        limit: 40,
      );
      if (_isDisposed) return;
      if (response['success'] == true && response['data'] != null) {
        final songs = List<Map<String, dynamic>>.from(
          response['data']['results'] ?? [],
        );
        if (!_isDisposed) {
          setState(() {
            _songs = songs;
          });
          _animationController.forward();
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _error = e.toString();
        });
      }
    }
    if (!_isDisposed) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    if (_isDisposed) return;
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    try {
      playerState.setSongLoading(true);
      playerState.setPlaylist(_songs);
      int index = _songs.indexWhere((s) => s['id'] == song['id']);
      playerState.setSongIndex(index == -1 ? 0 : index);

      // Build the playlist
      final playlist = ConcatenatingAudioSource(
        children: _songs.map((songData) {
          String? downloadUrl;
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
          final title = songData['title'] ?? songData['name'] ?? 'Unknown Song';
          final album = songData['album']?['name'] ?? 'Unknown Album';
          final artist =
              (songData['artists'] != null &&
                  songData['artists']['primary'] != null &&
                  songData['artists']['primary'].isNotEmpty)
              ? songData['artists']['primary'][0]['name']
              : (songData['subtitle'] ?? 'Unknown Artist');
          final imageField = songData['image'];
          String? artUri;
          if (imageField != null) {
            if (imageField is List && imageField.isNotEmpty) {
              for (var img in imageField.reversed) {
                if (img is Map && img['link'] != null) {
                  artUri = img['link'];
                  break;
                }
                if (img is Map && img['url'] != null) {
                  artUri = img['url'];
                  break;
                }
              }
            } else if (imageField is String) {
              artUri = imageField;
            }
          }
          final mediaItem = MediaItem(
            id: songData['id'],
            album: album,
            title: title,
            artist: artist,
            artUri: artUri != null ? Uri.parse(artUri) : null,
            extras: songData,
          );
          return AudioSource.uri(Uri.parse(downloadUrl ?? ""), tag: mediaItem);
        }).toList(),
      );

      await audioPlayer.stop();
      await audioPlayer.seek(Duration.zero);

      await audioPlayer.setAudioSource(playlist, initialIndex: index);
      // Immediately update provider for first time sync
      playerState.setSongIndex(index);
      playerState.setSong(_songs[index]);
      await audioPlayer.play();
      playerState.setPlaying(true);
      playerState.setSong(_songs[index]);
    } catch (e) {
      if (!_isDisposed) {
        playerState.setSongLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing song: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
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

  void _openMusicPlayer(Map<String, dynamic> song) {
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );

    final isCurrentSong =
        playerState.currentSong != null &&
        playerState.currentSong!['id'] == song['id'];

    if (!isCurrentSong) {
      _playSong(song);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Consumer<PlayerStateProvider>(
          builder: (context, playerState, _) {
            final currentSong = playerState.currentSong ?? song;
            final songTitle =
                currentSong['name'] ?? currentSong['title'] ?? 'Unknown Song';
            String artistName = 'Unknown Artist';
            if (currentSong['artists'] != null) {
              final artists = currentSong['artists'];
              if (artists['primary'] != null && artists['primary'].isNotEmpty) {
                artistName = artists['primary'][0]['name'] ?? 'Unknown Artist';
              }
            } else if (currentSong['subtitle'] != null) {
              artistName = currentSong['subtitle'];
            }
            final albumArtUrl = _getBestImageUrl(currentSong['image']) ?? '';
            return StreamBuilder<bool>(
              stream: audioPlayer.playingStream,
              builder: (context, playingSnapshot) {
                return StreamBuilder<Duration>(
                  stream: audioPlayer.positionStream,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration?>(
                      stream: audioPlayer.durationStream,
                      builder: (context, durationSnapshot) {
                        return MusicPlayerPage(
                          songTitle: songTitle,
                          artistName: artistName,
                          albumArtUrl: albumArtUrl,
                          songId: currentSong['id'],
                          isPlaying: playingSnapshot.data ?? false,
                          isLoading: playerState.isSongLoading,
                          currentPosition:
                              positionSnapshot.data ?? Duration.zero,
                          totalDuration: durationSnapshot.data ?? Duration.zero,
                          onPlayPause: () {
                            if (audioPlayer.playing) {
                              audioPlayer.pause();
                            } else {
                              audioPlayer.play();
                            }
                          },
                          onNext: () async {
                            await audioPlayer.seekToNext();
                          },
                          onPrevious: () async {
                            await audioPlayer.seekToPrevious();
                          },
                          onJumpToSong: (index) async {
                            await audioPlayer.seek(Duration.zero, index: index);
                            await audioPlayer.play();
                          },
                          onSeek: (value) {
                            final position =
                                (durationSnapshot.data ?? Duration.zero) *
                                value;
                            audioPlayer.seek(position);
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    ).then((_) {
      _syncPlayerState();
    });
  }

  Widget _buildSongCard(
    Map<String, dynamic> song,
    int index, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
          onTap: () => _openMusicPlayer(song),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              );
                            },
                          )
                        : const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: customColorsEnabled
                          ? [primaryColor, primaryColor.withOpacity(0.8)]
                          : [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: customColorsEnabled
                            ? primaryColor.withOpacity(0.4)
                            : const Color(0xFF6366f1).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Consumer<PlayerStateProvider>(
                    builder: (context, playerState, child) {
                      final isCurrentSong =
                          playerState.currentSong != null &&
                          playerState.currentSong!['id'] == song['id'];
                      final isPlaying = playerState.isPlaying && isCurrentSong;
                      final isLoading =
                          playerState.isSongLoading && isCurrentSong;

                      return IconButton(
                        icon: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                try {
                                  if (isCurrentSong && playerState.isPlaying) {
                                    await audioPlayer.pause();
                                    playerState.setPlaying(false);
                                  } else if (isCurrentSong &&
                                      !playerState.isPlaying) {
                                    await audioPlayer.play();
                                    playerState.setPlaying(true);
                                  } else {
                                    _playSong(song);
                                  }
                                } catch (e) {
                                  final actuallyPlaying = audioPlayer.playing;
                                  playerState.setPlaying(actuallyPlaying);
                                }
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground({
    required bool isPitchBlack,
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPitchBlack
            ? null
            : customColorsEnabled
            ? RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  secondaryColor,
                  secondaryColor.withOpacity(0.8),
                  Colors.black,
                ],
              )
            : const RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Colors.black],
              ),
        color: isPitchBlack ? Colors.black : null,
      ),
    );
  }

  Widget _buildHeader({
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: customColorsEnabled
              ? [secondaryColor, Colors.black.withOpacity(0.8)]
              : [const Color(0xFF1a1a2e), Colors.black.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Future.microtask(() => Navigator.pop(context));
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: customColorsEnabled
                            ? [primaryColor, primaryColor.withOpacity(0.8)]
                            : [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_songs.length} Songs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: customColorsEnabled
                            ? [primaryColor, primaryColor.withOpacity(0.7)]
                            : [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Popular Songs',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    final secondaryColor = customTheme.secondaryColor;

    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(
            isPitchBlack: isPitchBlack,
            customColorsEnabled: customColorsEnabled,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
          Column(
            children: [
              _buildHeader(
                customColorsEnabled: customColorsEnabled,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: customColorsEnabled
                                      ? [
                                          primaryColor,
                                          primaryColor.withOpacity(0.8),
                                        ]
                                      : [Color(0xFFff7d78), Color(0xFF9c27b0)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Loading ${widget.artistName}\'s songs...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Oops! Something went wrong',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: customColorsEnabled
                                        ? [
                                            primaryColor,
                                            primaryColor.withOpacity(0.8),
                                          ]
                                        : [
                                            Color(0xFFff7d78),
                                            Color(0xFF9c27b0),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _searchArtistSongs,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      'Try Again',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _songs.isEmpty
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFff7d78).withOpacity(0.3),
                                      const Color(0xFF9c27b0).withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.music_off,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Songs Found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No songs found for ${widget.artistName}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: _searchArtistSongs,
                          color: const Color(0xFFff7d78),
                          backgroundColor: isPitchBlack
                              ? Colors.black
                              : Colors.black,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            itemCount: _songs.length,
                            itemBuilder: (context, index) {
                              return _buildSongCard(
                                _songs[index],
                                index,
                                customColorsEnabled: customColorsEnabled,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor,
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
