import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/liked_song.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';
import '../services/player_state_provider.dart';
import '../services/liked_song_service.dart';
import '../screens/music_player.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({Key? key}) : super(key: key);

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen>
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

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<int?>? _currentIndexSub;
  late AudioPlayer audioPlayer;
  late PlayerStateProvider playerState;

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

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
      playerState = Provider.of<PlayerStateProvider>(context, listen: false);

      _playingSub = audioPlayer.playingStream.listen((playing) {
        playerState.setPlaying(playing);
        if (mounted && !_isDisposed) setState(() {});
      });

      _currentIndexSub = audioPlayer.currentIndexStream.listen((index) {
        final likedSongs = Hive.box<LikedSong>('likedSongs').values.toList();
        if (playerState.currentContext == "liked" &&
            index != null &&
            index >= 0 &&
            index < likedSongs.length) {
          playerState.setSongIndex(index);
          playerState.setSong({
            'id': likedSongs[index].id,
            'name': likedSongs[index].title,
            'primaryArtists': likedSongs[index].artist,
            'image': likedSongs[index].imageUrl,
            'downloadUrl': likedSongs[index].downloadUrl,
          });
          if (mounted && !_isDisposed) setState(() {});
        }
      });
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
    super.dispose();
  }

  void _syncPlayerState() {
    playerState.setPlaying(audioPlayer.playing);
    if (mounted && !_isDisposed) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncPlayerState();
    }
  }

  Widget _buildAnimatedBackground({
    required bool isPitchBlack,
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
    required bool useDynamicColors,
    required ColorScheme scheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPitchBlack
            ? Colors.black
            : useDynamicColors
            ? scheme.background
            : customColorsEnabled
            ? secondaryColor
            : null,
        gradient: isPitchBlack || customColorsEnabled || useDynamicColors
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
              useDynamicColors
                  ? scheme.primary
                  : customColorsEnabled
                  ? primaryColor
                  : const Color(0xFF6366f1),
            ),
          ),
          // Floating musical notes
          ...List.generate(
            8,
            (index) => _buildFloatingNote(
              index,
              useDynamicColors
                  ? scheme.primary
                  : customColorsEnabled
                  ? primaryColor
                  : const Color(0xFF8b5cf6),
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
    final customTheme = Provider.of<CustomThemeProvider>(
      context,
      listen: false,
    );
    final useDynamicColors = customTheme.useDynamicColors;
    final scheme = Theme.of(context).colorScheme;
    final headingColor = customColorsEnabled
        ? primaryColor
        : (useDynamicColors ? scheme.primary : const Color(0xFF6366f1));
    final subtitleColor = useDynamicColors
        ? scheme.onBackground
        : Colors.grey[400];
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
                      'Favorite Collection',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Liked Songs',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: headingColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
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
    required bool useDynamicColors,
    required ColorScheme scheme,
    required Color secondaryColor,
  }) {
    final iconColor = useDynamicColors
        ? scheme.primary
        : customColorsEnabled
        ? primaryColor
        : const Color(0xFF6366f1);
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
                  color: iconColor,
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
                child: Icon(
                  Icons.favorite_rounded,
                  color: customColorsEnabled && primaryColor == Colors.white
                      ? secondaryColor
                      : Colors.white,
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
                      'Songs you love',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Clear liked songs button removed
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
                    Icons.favorite_border_rounded,
                    size: 50,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'No Liked Songs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Start exploring music and like\nyour favorite tracks',
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

  Future<void> _playLikedSong(
    LikedSong song,
    int index,
    List<LikedSong> likedSongs,
  ) async {
    try {
      playerState.setSongLoading(true);

      // Build liked songs playlist
      final sources = likedSongs
          .map(
            (s) => AudioSource.uri(
              Uri.parse(s.downloadUrl ?? ''),
              tag: MediaItem(
                id: s.id,
                album: '',
                title: s.title,
                artist: s.artist,
                artUri: s.imageUrl.isNotEmpty ? Uri.parse(s.imageUrl) : null,
              ),
            ),
          )
          .toList();

      final playlistSource = ConcatenatingAudioSource(children: sources);

      playerState.setPlaylist(
        likedSongs
            .map(
              (s) => {
                'id': s.id,
                'name': s.title,
                'primaryArtists': s.artist,
                'image': s.imageUrl,
                'downloadUrl': s.downloadUrl,
              },
            )
            .toList(),
      );
      playerState.setSongIndex(index);
      playerState.setSong({
        'id': song.id,
        'name': song.title,
        'primaryArtists': song.artist,
        'image': song.imageUrl,
        'downloadUrl': song.downloadUrl,
      });

      // Mark context as liked
      playerState.setCurrentContext("liked");

      await audioPlayer.setAudioSource(playlistSource, initialIndex: index);
      await audioPlayer.play();
      playerState.setPlaying(true);
      playerState.setSongLoading(false);
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

  void _openMusicPlayer(
    LikedSong song,
    int index,
    List<LikedSong> likedSongs,
  ) async {
    final isCurrentSong =
        playerState.currentSong != null &&
        playerState.currentSong!['id'] == song.id &&
        playerState.currentContext == "liked";

    if (!isCurrentSong) {
      await _playLikedSong(song, index, likedSongs);
    }

    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => StreamBuilder<bool>(
              stream: audioPlayer.playingStream,
              builder: (context, playingSnapshot) {
                return StreamBuilder<Duration>(
                  stream: audioPlayer.positionStream,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration?>(
                      stream: audioPlayer.durationStream,
                      builder: (context, durationSnapshot) {
                        return MusicPlayerPage(
                          songTitle: song.title,
                          artistName: song.artist,
                          albumArtUrl: song.imageUrl,
                          songId: song.id,
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
                            final currentIndex = likedSongs.indexWhere(
                              (s) => s.id == song.id,
                            );
                            if (currentIndex != -1 &&
                                currentIndex < likedSongs.length - 1) {
                              await _playLikedSong(
                                likedSongs[currentIndex + 1],
                                currentIndex + 1,
                                likedSongs,
                              );
                            }
                          },
                          onPrevious: () async {
                            final currentIndex = likedSongs.indexWhere(
                              (s) => s.id == song.id,
                            );
                            if (currentIndex > 0) {
                              await _playLikedSong(
                                likedSongs[currentIndex - 1],
                                currentIndex - 1,
                                likedSongs,
                              );
                            }
                          },
                          onJumpToSong: (jumpIndex) async {
                            if (jumpIndex >= 0 &&
                                jumpIndex < likedSongs.length) {
                              await _playLikedSong(
                                likedSongs[jumpIndex],
                                jumpIndex,
                                likedSongs,
                              );
                            }
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
            ),
          ),
        )
        .then((_) {
          if (mounted && !_isDisposed) setState(() {});
        });
  }

  Widget _buildSongsList({
    required bool customColorsEnabled,
    required Color primaryColor,
    required List<LikedSong> songs,
    required bool useDynamicColors,
    required ColorScheme scheme,
    required Color secondaryColor,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrentSong =
            playerState.currentSong?['id'] == song.id &&
            playerState.currentContext == "liked";

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
                    useDynamicColors,
                    scheme,
                    secondaryColor,
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
    LikedSong song,
    int index,
    List<LikedSong> likedSongs,
    bool isCurrentSong,
    bool isPlaying,
    bool isLoading,
    bool customColorsEnabled,
    Color primaryColor,
    double animationProgress,
    bool useDynamicColors,
    ColorScheme scheme,
    Color secondaryColor,
  ) {
    final shouldShowPause =
        isCurrentSong && isPlaying && playerState.currentContext == "liked";
    final showLoader =
        isCurrentSong && isLoading && playerState.currentContext == "liked";

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
                    onTap: () => _openMusicPlayer(song, index, likedSongs),
                    child: Padding(
                      padding: playlistCardPadding,
                      child: Row(
                        children: [
                          // Album art
                          Hero(
                            tag: 'liked_album_art_${song.id}_$index',
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
                                  child: song.imageUrl.isNotEmpty
                                      ? Image.network(
                                          song.imageUrl,
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
                                  song.title,
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
                                  song.artist.isNotEmpty
                                      ? song.artist
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
                                          color:
                                              customColorsEnabled &&
                                                  primaryColor == Colors.white
                                              ? secondaryColor
                                              : primaryColor,
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Play/pause button
                              Transform.scale(
                                scale: (0.5 + (0.5 * animationProgress)).clamp(
                                  0.1,
                                  1.0,
                                ),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: useDynamicColors
                                        ? scheme.primary
                                        : customColorsEnabled
                                        ? primaryColor
                                        : const Color(0xFF6366f1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: customColorsEnabled
                                            ? primaryColor.withOpacity(0.35)
                                            : const Color(
                                                0xFFff7d78,
                                              ).withOpacity(0.35),
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
                                              if (isCurrentSong &&
                                                  shouldShowPause) {
                                                await audioPlayer.pause();
                                                playerState.setPlaying(false);
                                              } else if (isCurrentSong &&
                                                  !shouldShowPause) {
                                                await audioPlayer.play();
                                                playerState.setPlaying(true);
                                              } else {
                                                await _playLikedSong(
                                                  song,
                                                  index,
                                                  likedSongs,
                                                );
                                              }
                                              if (mounted && !_isDisposed)
                                                setState(() {});
                                            },
                                      child: showLoader
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Icon(
                                              shouldShowPause
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color:
                                                  customColorsEnabled &&
                                                      primaryColor ==
                                                          Colors.white
                                                  ? secondaryColor
                                                  : Colors.white,
                                              size: 18,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              Transform.scale(
                                scale: (0.5 + (0.5 * animationProgress)).clamp(
                                  0.1,
                                  1.0,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    await LikedSongService.removeFromLikedSongs(
                                      song.id,
                                    );
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, _) {
        final likedSongsBox = Hive.box<LikedSong>('likedSongs');
        final isPitchBlack = context
            .watch<PitchBlackThemeProvider>()
            .isPitchBlack;
        final customTheme = context.watch<CustomThemeProvider>();
        final customColorsEnabled = customTheme.customColorsEnabled;
        final primaryColor = customTheme.primaryColor;
        final secondaryColor = customTheme.secondaryColor;
        final useDynamicColors = customTheme.useDynamicColors;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: isPitchBlack
              ? Colors.black
              : useDynamicColors
              ? scheme.background
              : customColorsEnabled
              ? secondaryColor
              : const Color(0xFF0a0a0a),
          body: Stack(
            children: [
              _buildAnimatedBackground(
                isPitchBlack: isPitchBlack,
                customColorsEnabled: customColorsEnabled,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                useDynamicColors: useDynamicColors,
                scheme: scheme,
              ),
              Column(
                children: [
                  _buildHeader(
                    customColorsEnabled: customColorsEnabled,
                    primaryColor: primaryColor,
                  ),
                  ValueListenableBuilder(
                    valueListenable: likedSongsBox.listenable(),
                    builder: (context, Box<LikedSong> box, _) {
                      return _buildStatsSection(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                        songCount: box.values.length,
                        useDynamicColors: customTheme.useDynamicColors,
                        scheme: Theme.of(context).colorScheme,
                        secondaryColor: secondaryColor,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: likedSongsBox.listenable(),
                      builder: (context, Box<LikedSong> box, _) {
                        final songs = box.values.toList();

                        if (songs.isEmpty) {
                          return _buildEmptyState(
                            customColorsEnabled: customColorsEnabled,
                            primaryColor: primaryColor,
                          );
                        }

                        return _buildSongsList(
                          customColorsEnabled: customColorsEnabled,
                          primaryColor: primaryColor,
                          songs: songs,
                          useDynamicColors: customTheme.useDynamicColors,
                          scheme: Theme.of(context).colorScheme,
                          secondaryColor: secondaryColor,
                        );
                      },
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
