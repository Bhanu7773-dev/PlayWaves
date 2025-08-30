import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../services/player_state_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';

class RecentlyPlayedScreen extends StatefulWidget {
  const RecentlyPlayedScreen({Key? key}) : super(key: key);

  @override
  State<RecentlyPlayedScreen> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _waveController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fadeController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _extractPlayableUrl(Map<String, dynamic> song) {
    var urlField = song['downloadUrl'];
    // Always choose the highest quality (e.g., '320kbps') if available
    if (urlField is List && urlField.isNotEmpty) {
      for (var item in urlField) {
        if (item is Map &&
            item['quality'] == '320kbps' &&
            item['url'] is String &&
            item['url'].isNotEmpty) {
          return item['url'];
        }
      }
      // Fallback: first valid url in list
      for (var item in urlField) {
        if (item is Map && item['url'] is String && item['url'].isNotEmpty) {
          return item['url'];
        }
        if (item is String && item.isNotEmpty) return item;
      }
    }
    if (urlField is String && urlField.isNotEmpty) return urlField;
    if (song['media_url'] is String && song['media_url'].isNotEmpty) {
      return song['media_url'];
    }
    if (song['media_preview_url'] is String &&
        song['media_preview_url'].isNotEmpty) {
      return song['media_preview_url'];
    }
    return '';
  }

  String _getBestImageUrl(dynamic images) {
    if (images is String && images.isNotEmpty) return images;
    if (images is List && images.isNotEmpty) {
      for (var img in images.reversed) {
        if (img is Map && img['url'] is String && img['url'].isNotEmpty) {
          return img['url'];
        }
        if (img is Map && img['link'] is String && img['link'].isNotEmpty) {
          return img['link'];
        }
      }
      if (images.first is String) return images.first;
    }
    return '';
  }

  String _getArtistName(Map<String, dynamic> song) {
    if (song['artists'] != null &&
        song['artists'] is Map &&
        song['artists']['primary'] is List &&
        (song['artists']['primary'] as List).isNotEmpty) {
      return song['artists']['primary'][0]['name'] ?? 'Unknown Artist';
    } else if (song['primaryArtists'] != null &&
        song['primaryArtists'].toString().isNotEmpty) {
      return song['primaryArtists'];
    } else if (song['artist'] != null && song['artist'].toString().isNotEmpty) {
      return song['artist'];
    } else if (song['subtitle'] != null &&
        song['subtitle'].toString().isNotEmpty) {
      return song['subtitle'];
    }
    return 'Unknown Artist';
  }

  Future<void> _playRecentlyPlayedSong(
    Map<String, dynamic> song,
    int index,
    List<Map<String, dynamic>> songList,
  ) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
    try {
      playerState.setSongLoading(true);
      final sources = songList
          .map(
            (s) => AudioSource.uri(
              Uri.parse(_extractPlayableUrl(s)),
              tag: MediaItem(
                id: s['id'] ?? '',
                album: '',
                title: s['name'] ?? s['title'] ?? '',
                artist: _getArtistName(s),
                artUri: _getBestImageUrl(s['image']).isNotEmpty
                    ? Uri.parse(_getBestImageUrl(s['image']))
                    : null,
              ),
            ),
          )
          .where((source) {
            final uri = (source as UriAudioSource).uri;
            return uri.toString().isNotEmpty;
          })
          .toList();
      playerState.setPlaylist(
        songList
            .map(
              (s) => {
                'id': s['id'],
                'name': s['name'] ?? s['title'] ?? '',
                'primaryArtists':
                    s['primaryArtists'] ?? s['artist'] ?? s['subtitle'] ?? '',
                'image': s['image'],
                'downloadUrl': _extractPlayableUrl(s),
              },
            )
            .toList(),
      );
      playerState.setSongIndex(index);
      playerState.setSong({
        'id': song['id'],
        'name': song['name'] ?? song['title'] ?? '',
        'primaryArtists':
            song['primaryArtists'] ?? song['artist'] ?? song['subtitle'] ?? '',
        'image': song['image'],
        'downloadUrl': _extractPlayableUrl(song),
      });
      playerState.setCurrentContext("recentlyPlayed");
      if (sources.isNotEmpty) {
        await audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: sources),
          initialIndex: index,
        );
        await audioPlayer.play();
        playerState.setPlaying(true);
        playerState.setSongLoading(false);
      } else {
        throw Exception('No playable sources in playlist.');
      }
    } catch (e) {
      playerState.setSongLoading(false);
      if (mounted && !_isDisposed) {
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
    if (mounted && !_isDisposed) setState(() {});
  }

  Widget _buildAnimatedBackground({
    required bool isPitchBlack,
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: isPitchBlack
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black],
                  )
                : customColorsEnabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      secondaryColor.withOpacity(0.95),
                      primaryColor.withOpacity(0.1),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1a0033),
                      Color(0xFF2d1b69),
                      Color(0xFF0f0f23),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
          ),
          child: Stack(
            children: [
              // Animated circles
              ...List.generate(5, (index) {
                return _buildFloatingCircle(
                  index,
                  customColorsEnabled,
                  primaryColor,
                  secondaryColor,
                  isPitchBlack,
                );
              }),
              // Musical notes
              ...List.generate(8, (index) {
                return _buildFloatingNote(
                  index,
                  customColorsEnabled,
                  primaryColor,
                  isPitchBlack,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCircle(
    int index,
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
    bool isPitchBlack,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final double progress = (_pulseAnimation.value + (index * 0.25)) % 1.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Positioned(
          left:
              (index * 80.0 + math.sin(progress * 2 * math.pi) * 40) %
              screenWidth,
          top:
              (index * 100.0 + math.cos(progress * 2 * math.pi) * 25) %
              screenHeight,
          child: Container(
            width: 60 + math.sin(progress * math.pi) * 15,
            height: 60 + math.sin(progress * math.pi) * 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isPitchBlack
                    ? [Colors.transparent, Colors.transparent]
                    : customColorsEnabled
                    ? [
                        primaryColor.withOpacity(0.08),
                        primaryColor.withOpacity(0.03),
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFFff7d78).withOpacity(0.12),
                        const Color(0xFF9c27b0).withOpacity(0.08),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingNote(
    int index,
    bool customColorsEnabled,
    Color primaryColor,
    bool isPitchBlack,
  ) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        final double progress = (_waveAnimation.value + (index * 0.18)) % 1.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Positioned(
          left: (index * 70.0) % screenWidth,
          top:
              (index * 85.0 + math.sin(progress * 2 * math.pi) * 35) %
              screenHeight,
          child: Transform.rotate(
            angle: progress * 2 * math.pi,
            child: Icon(
              Icons.music_note,
              size: 16 + math.sin(progress * math.pi) * 6,
              color: isPitchBlack
                  ? Colors.transparent
                  : customColorsEnabled
                  ? primaryColor.withOpacity(0.15)
                  : const Color(0xFFff7d78).withOpacity(0.25),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool customColorsEnabled,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.8,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Music History',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: customColorsEnabled
                        ? [primaryColor, primaryColor.withOpacity(0.7)]
                        : const [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Recently Played',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection({
    required bool customColorsEnabled,
    required Color primaryColor,
    required int songCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: customColorsEnabled
                    ? [primaryColor, primaryColor.withOpacity(0.7)]
                    : const [Color(0xFFff7d78), Color(0xFF9c27b0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: customColorsEnabled
                      ? primaryColor.withOpacity(0.25)
                      : const Color(0xFFff7d78).withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$songCount Tracks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total songs in your history',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (songCount > 0)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _pulseAnimation.value * 0.12,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: customColorsEnabled
                          ? primaryColor.withOpacity(0.15)
                          : const Color(0xFFff7d78).withOpacity(0.15),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: customColorsEnabled
                          ? primaryColor
                          : const Color(0xFFff7d78),
                      size: 22,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool customColorsEnabled,
    required Color primaryColor,
  }) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: customColorsEnabled
                      ? [
                          primaryColor.withOpacity(0.15),
                          primaryColor.withOpacity(0.04),
                        ]
                      : [
                          const Color(0xFFff7d78).withOpacity(0.15),
                          const Color(0xFF9c27b0).withOpacity(0.08),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 60,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Recent Tracks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your music history will appear here\nonce you start playing songs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList({
    required bool customColorsEnabled,
    required Color primaryColor,
    required List<Map<String, dynamic>> songs,
  }) {
    final playerState = Provider.of<PlayerStateProvider>(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isCurrentSong =
              playerState.currentSong?['id'] == song['id'] &&
              playerState.currentContext == "recentlyPlayed";
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 250 + (index * 40)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 16),
                child: Opacity(
                  opacity: value,
                  child: _buildSongCard(
                    song,
                    index,
                    songs,
                    isCurrentSong,
                    isCurrentSong && playerState.isPlaying,
                    isCurrentSong && playerState.isSongLoading,
                    customColorsEnabled,
                    primaryColor,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSongCard(
    Map<String, dynamic> song,
    int index,
    List<Map<String, dynamic>> songList,
    bool isCurrentSong,
    bool isPlaying,
    bool isLoading,
    bool customColorsEnabled,
    Color primaryColor,
  ) {
    final imageUrl = _getBestImageUrl(song['image']);
    final songTitle = song['name'] ?? song['title'] ?? 'Unknown Song';
    final artistName = _getArtistName(song);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isCurrentSong
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: isCurrentSong
              ? customColorsEnabled
                    ? primaryColor.withOpacity(0.25)
                    : const Color(0xFFff7d78).withOpacity(0.25)
              : Colors.white.withOpacity(0.06),
          width: isCurrentSong ? 1.2 : 0.8,
        ),
        boxShadow: isCurrentSong
            ? [
                BoxShadow(
                  color: customColorsEnabled
                      ? primaryColor.withOpacity(0.15)
                      : const Color(0xFFff7d78).withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _playRecentlyPlayedSong(song, index, songList),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Album Art
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: customColorsEnabled
                          ? [
                              primaryColor.withOpacity(0.25),
                              primaryColor.withOpacity(0.08),
                            ]
                          : [
                              const Color(0xFFff7d78).withOpacity(0.25),
                              const Color(0xFF9c27b0).withOpacity(0.15),
                            ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.music_note_rounded,
                                color: customColorsEnabled
                                    ? primaryColor
                                    : const Color(0xFFff7d78),
                                size: 24,
                              );
                            },
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            color: customColorsEnabled
                                ? primaryColor
                                : const Color(0xFFff7d78),
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTitle,
                        style: TextStyle(
                          color: isCurrentSong
                              ? customColorsEnabled
                                    ? primaryColor
                                    : const Color(0xFFff7d78)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              artistName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
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
                const SizedBox(width: 10),
                // Play Button
                _buildPlayButton(
                  song,
                  index,
                  songList,
                  isCurrentSong,
                  isPlaying,
                  isLoading,
                  customColorsEnabled,
                  primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(
    Map<String, dynamic> song,
    int index,
    List<Map<String, dynamic>> songList,
    bool isCurrentSong,
    bool isPlaying,
    bool isLoading,
    bool customColorsEnabled,
    Color primaryColor,
  ) {
    final shouldShowPause = isCurrentSong && isPlaying;
    final showLoader = isCurrentSong && isLoading;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: customColorsEnabled
              ? [primaryColor, primaryColor.withOpacity(0.8)]
              : const [Color(0xFFff7d78), Color(0xFF9c27b0)],
        ),
        boxShadow: [
          BoxShadow(
            color: customColorsEnabled
                ? primaryColor.withOpacity(0.35)
                : const Color(0xFFff7d78).withOpacity(0.35),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: showLoader
              ? null
              : () async {
                  final playerState = Provider.of<PlayerStateProvider>(
                    context,
                    listen: false,
                  );
                  final audioPlayer = Provider.of<AudioPlayer>(
                    context,
                    listen: false,
                  );
                  if (isCurrentSong && shouldShowPause) {
                    await audioPlayer.pause();
                    playerState.setPlaying(false);
                  } else if (isCurrentSong && !shouldShowPause) {
                    await audioPlayer.play();
                    playerState.setPlaying(true);
                  } else {
                    await _playRecentlyPlayedSong(song, index, songList);
                  }
                  if (mounted && !_isDisposed) setState(() {});
                },
          child: showLoader
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  shouldShowPause
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
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
    final recentlyPlayed = context.watch<PlayerStateProvider>().recentlyPlayed;

    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : const Color(0xFF0a0a0a),
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
              ),
              _buildStatsSection(
                customColorsEnabled: customColorsEnabled,
                primaryColor: primaryColor,
                songCount: recentlyPlayed.length,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: recentlyPlayed.isEmpty
                    ? _buildEmptyState(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                      )
                    : _buildSongsList(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                        songs: recentlyPlayed,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
