import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _particleController;
  late AnimationController _cardController;
  bool _isDisposed = false;

  late AudioPlayer _audioPlayer;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<ProcessingState>? _processingStateSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();

    // Initialize entrance animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    // Background particle animation (continuous)
    _particleController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    // Card entrance animation controller
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Start entrance animations with delays
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardController.forward();
    });

    // Listen to AudioPlayer state changes
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );

    _currentIndexSub = _audioPlayer.currentIndexStream.listen((index) {
      final recentlyPlayed = playerState.recentlyPlayed;
      if (playerState.currentContext == "recentlyPlayed" &&
          index != null &&
          index >= 0 &&
          index < recentlyPlayed.length) {
        playerState.setSongIndex(index);
        playerState.setSong(recentlyPlayed[index]);
        if (mounted && !_isDisposed) setState(() {});
      }
    });

    _processingStateSub = _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed || state == ProcessingState.idle) {
        playerState.setPlaying(false);
        if (mounted && !_isDisposed) setState(() {});
      }
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((playerStateValue) {
      playerState.setPlaying(playerStateValue.playing);
      if (mounted && !_isDisposed) setState(() {});
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fadeController.dispose();
    _slideController.dispose();
    _headerController.dispose();
    _particleController.dispose();
    _cardController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _playingSub?.cancel();
    _currentIndexSub?.cancel();
    _processingStateSub?.cancel();
    _playerStateSub?.cancel();
    super.dispose();
  }

  void _syncPlayerState() {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    playerState.setPlaying(_audioPlayer.playing);
    if (mounted && !_isDisposed) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncPlayerState();
    }
  }

  String _extractPlayableUrl(Map<String, dynamic> song) {
    var urlField = song['downloadUrl'];
    if (urlField is List && urlField.isNotEmpty) {
      for (var item in urlField) {
        if (item is Map &&
            item['quality'] == '320kbps' &&
            item['url'] is String &&
            item['url'].isNotEmpty) {
          return item['url'];
        }
      }
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

  Widget _buildAnimatedBackground({
    required bool isPitchBlack,
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPitchBlack
            ? Colors.black
            : customColorsEnabled
            ? secondaryColor
            : null,
        gradient: isPitchBlack || customColorsEnabled
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2d1b69),
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Colors.black,
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
      ),
      child: Stack(
        children: [
          // Floating particles
          ...List.generate(
            18,
            (index) => _buildFloatingParticle(
              index,
              customColorsEnabled ? primaryColor : const Color(0xFF6366f1),
            ),
          ),
          // Floating musical notes
          ...List.generate(
            8,
            (index) => _buildFloatingNote(
              index,
              customColorsEnabled ? primaryColor : const Color(0xFF8b5cf6),
            ),
          ),
          // Floating orbs
          ...List.generate(
            4,
            (index) => _buildFloatingOrb(
              index,
              customColorsEnabled ? primaryColor : const Color(0xFF6366f1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index, Color color) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.08) % 1.0;
        final size = MediaQuery.of(context).size;

        final xOffset = (index * 70.0) % size.width;
        final yOffset = (index * 90.0) % size.height;

        final x = xOffset + math.sin(progress * 2 * math.pi + index) * 25;
        final y = yOffset + math.cos(progress * 2 * math.pi + index * 0.7) * 30;

        final opacity = (math.sin(progress * math.pi) * 0.4 + 0.2).clamp(
          0.0,
          0.6,
        );
        final scale = 0.6 + math.sin(progress * 2 * math.pi) * 0.2;

        return Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 2 + (index % 4),
                height: 2 + (index % 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingNote(int index, Color color) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.15) % 1.0;
        final size = MediaQuery.of(context).size;

        final x = (index * 80.0) % size.width;
        final y =
            (index * 120.0 + math.sin(progress * 2 * math.pi) * 40) %
            size.height;

        final opacity = (0.6 - progress * 0.3).clamp(0.0, 0.4);
        final rotation = progress * 2 * math.pi;

        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity,
              child: Icon(
                Icons.music_note,
                size: 14 + math.sin(progress * math.pi) * 4,
                color: color.withOpacity(0.6),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingOrb(int index, Color color) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.25) % 1.0;
        final size = MediaQuery.of(context).size;

        final x = (size.width * 0.9 * progress + index * 120) % size.width;
        final y =
            size.height * 0.2 +
            math.sin(progress * math.pi + index * 1.5) * size.height * 0.5;

        final opacity = (0.5 - progress * 0.3).clamp(0.0, 0.3);
        final scale = 1.2 - progress * 0.6;

        return Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 40 + index * 15,
                height: 40 + index * 15,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
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
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _headerController,
                curve: Curves.easeOutBack,
              ),
            ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: customColorsEnabled
                            ? [primaryColor, primaryColor.withOpacity(0.7)]
                            : [
                                const Color(0xFF6366f1),
                                const Color(0xFF8b5cf6),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Recently Played',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection({
    required bool customColorsEnabled,
    required Color primaryColor,
    required int songCount,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: customColorsEnabled
                        ? [primaryColor, primaryColor.withOpacity(0.7)]
                        : [const Color(0xFF6366f1), const Color(0xFF8b5cf6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: customColorsEnabled
                          ? primaryColor.withOpacity(0.25)
                          : const Color(0xFFff7d78).withOpacity(0.25),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$songCount Tracks',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total songs in your history',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (songCount > 0)
                GestureDetector(
                  onTap: () {
                    final playerState = Provider.of<PlayerStateProvider>(
                      context,
                      listen: false,
                    );
                    playerState.clearRecentlyPlayed();
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: customColorsEnabled
                          ? primaryColor.withOpacity(0.15)
                          : const Color(0xFF6366f1).withOpacity(0.15),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: customColorsEnabled
                          ? primaryColor
                          : const Color(0xFF6366f1),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: customColorsEnabled
                          ? [
                              primaryColor.withOpacity(0.15),
                              primaryColor.withOpacity(0.04),
                            ]
                          : [
                              const Color(0xFF6366f1).withOpacity(0.15),
                              const Color(0xFF8b5cf6).withOpacity(0.08),
                            ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 50,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'No Recent Tracks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your music history will appear here\nonce you start playing songs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playRecentlyPlayedSong(
    Map<String, dynamic> song,
    int index,
    List<Map<String, dynamic>> songs,
  ) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
    try {
      playerState.setSongLoading(true);

      final playlistCopy = songs.map((s) {
        final songCopy = Map<String, dynamic>.from(s);
        songCopy['downloadUrl'] = _extractPlayableUrl(songCopy);
        return songCopy;
      }).toList();

      playerState.setPlaylist(playlistCopy);
      playerState.setSongIndex(index);

      final songCopy = Map<String, dynamic>.from(song);
      songCopy['downloadUrl'] = _extractPlayableUrl(songCopy);
      playerState.setSong(songCopy);

      playerState.setCurrentContext("recentlyPlayed");

      final sources = playlistCopy
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
            final uri = source.uri;
            return uri.toString().isNotEmpty;
          })
          .toList();

      if (sources.isNotEmpty) {
        await audioPlayer.stop();
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

  Widget _buildSongsList({
    required bool customColorsEnabled,
    required Color primaryColor,
    required List<Map<String, dynamic>> songs,
  }) {
    final playerState = Provider.of<PlayerStateProvider>(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrentSong =
            playerState.currentSongIndex == index &&
            playerState.currentContext == "recentlyPlayed";

        return AnimatedBuilder(
          animation: _cardController,
          builder: (context, child) {
            final animationProgress = Curves.easeOutBack.transform(
              (_cardController.value - (index * 0.08)).clamp(0.0, 1.0),
            );

            return Transform.translate(
              offset: Offset(0, 30 * (1 - animationProgress)),
              child: Transform.scale(
                scale: 0.9 + (0.1 * animationProgress),
                child: Opacity(
                  opacity: animationProgress.clamp(0.0, 1.0),
                  child: _buildSongCard(
                    song,
                    index,
                    songs,
                    isCurrentSong,
                    isCurrentSong && playerState.isPlaying,
                    isCurrentSong && playerState.isSongLoading,
                    customColorsEnabled,
                    primaryColor,
                    animationProgress,
                  ),
                ),
              ),
            );
          },
        );
      },
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
    double animationProgress,
  ) {
    final imageUrl = _getBestImageUrl(song['image']);
    final songTitle = song['name'] ?? song['title'] ?? 'Unknown Song';
    final artistName = _getArtistName(song);

    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        final playlistCardMargin = const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 4,
        );
        final playlistCardPadding = const EdgeInsets.all(12);
        final albumArtSize = 50.0;
        final borderRadius = BorderRadius.circular(16);
        final albumArtRadius = BorderRadius.circular(12);
        final isCurrent = isCurrentSong;
        final gradientColors = isCurrent
            ? [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.05)]
            : [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)];
        final borderColor = isCurrent
            ? primaryColor.withOpacity(0.3)
            : Colors.white.withOpacity(0.1);
        final boxShadow = [
          BoxShadow(
            color: isCurrent
                ? primaryColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];
        final animationProgress = Curves.easeOutBack.transform(
          (_cardController.value - (index * 0.1)).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationProgress)),
          child: Transform.scale(
            scale: (0.8 + (0.2 * animationProgress)).clamp(0.1, 1.0),
            child: Opacity(
              opacity: animationProgress.clamp(0.0, 1.0),
              child: Container(
                margin: playlistCardMargin,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: boxShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: () => _playRecentlyPlayedSong(song, index, songList),
                    child: Padding(
                      padding: playlistCardPadding,
                      child: Row(
                        children: [
                          // Album art
                          Hero(
                            tag: 'recent_album_art_${song['id']}_$index',
                            child: Transform.rotate(
                              angle: ((1 - animationProgress) * 0.3).clamp(
                                0.0,
                                1.0,
                              ),
                              child: Container(
                                width: albumArtSize,
                                height: albumArtSize,
                                decoration: BoxDecoration(
                                  borderRadius: albumArtRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isCurrent
                                          ? primaryColor.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: albumArtRadius,
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return _buildDefaultArtwork(
                                                  customColorsEnabled,
                                                  primaryColor,
                                                );
                                              },
                                        )
                                      : _buildDefaultArtwork(
                                          customColorsEnabled,
                                          primaryColor,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Song information
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  songTitle,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? primaryColor
                                        : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  artistName.isNotEmpty
                                      ? artistName
                                      : 'Unknown Artist',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPlaying
                                              ? Icons.volume_up
                                              : Icons.pause,
                                          color: primaryColor,
                                          size: 10,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isPlaying ? 'Playing' : 'Paused',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Controls
                          _buildPlayButton(
                            song,
                            index,
                            songList,
                            isCurrent,
                            isPlaying,
                            isLoading,
                            customColorsEnabled,
                            primaryColor,
                            animationProgress,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    double animationProgress,
  ) {
    final shouldShowPause = isCurrentSong && isPlaying;
    final showLoader = isCurrentSong && isLoading;

    return Transform.scale(
      scale: 0.6 + (0.4 * animationProgress),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: customColorsEnabled
                ? [primaryColor, primaryColor.withOpacity(0.8)]
                : [const Color(0xFF6366f1), const Color(0xFF8b5cf6)],
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
            borderRadius: BorderRadius.circular(18),
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
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : StreamBuilder<bool>(
                    stream: _audioPlayer.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      final playerState = Provider.of<PlayerStateProvider>(
                        context,
                        listen: false,
                      );
                      final showPause =
                          isCurrentSong &&
                          isPlaying &&
                          playerState.currentContext == "recentlyPlayed";
                      return Icon(
                        showPause
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultArtwork(bool customColorsEnabled, Color primaryColor) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: customColorsEnabled
              ? primaryColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.5),
          size: 32,
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

    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, child) {
        final recentlyPlayed = playerState.recentlyPlayed;

        return Scaffold(
          backgroundColor: isPitchBlack
              ? Colors.black
              : const Color(0xFF0a0a0a),
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
                  const SizedBox(height: 20),
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
      },
    );
  }
}
