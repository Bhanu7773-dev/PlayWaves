import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../models/playlist_song.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';
import '../services/player_state_provider.dart';
import 'music_player.dart';

class MyPlaylistScreen extends StatefulWidget {
  const MyPlaylistScreen({Key? key}) : super(key: key);

  @override
  State<MyPlaylistScreen> createState() => _MyPlaylistScreenState();
}

class _MyPlaylistScreenState extends State<MyPlaylistScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _particleController;
  late AnimationController _cardController;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<int?>? _currentIndexSub;
  late AudioPlayer audioPlayer;
  late PlayerStateProvider playerState;
  bool _isDisposed = false;

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
      duration: const Duration(seconds: 20),
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _cardController.forward();
    });

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
      playerState = Provider.of<PlayerStateProvider>(context, listen: false);

      _playingSub = audioPlayer.playingStream.listen((playing) {
        playerState.setPlaying(playing);
        if (mounted && !_isDisposed) setState(() {});
      });

      _currentIndexSub = audioPlayer.currentIndexStream.listen((index) {
        final playlist = playerState.currentPlaylist;
        if (playerState.currentContext == "playlist" &&
            playlist.isNotEmpty &&
            index != null &&
            index >= 0 &&
            index < playlist.length) {
          playerState.setSongIndex(index);
          playerState.setSong(playlist[index]);
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
    final actuallyPlaying = audioPlayer.playing;
    playerState.setPlaying(actuallyPlaying);
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
            15,
            (index) => _buildFloatingParticle(
              index,
              useDynamicColors
                  ? scheme.primary
                  : customColorsEnabled
                  ? primaryColor
                  : const Color(0xFF6366f1),
            ),
          ),
          // Slow moving orbs
          ...List.generate(
            3,
            (index) => _buildFloatingOrb(
              index,
              useDynamicColors
                  ? scheme.primary
                  : customColorsEnabled
                  ? primaryColor
                  : const Color(0xFF8b5cf6),
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
        final progress = (_particleController.value + index * 0.1) % 1.0;
        final size = MediaQuery.of(context).size;

        // Create a more complex path for particles
        final xOffset = (index * 80.0) % size.width;
        final yOffset = (index * 120.0) % size.height;

        final x = xOffset + math.sin(progress * 2 * math.pi + index) * 30;
        final y = yOffset + math.cos(progress * 2 * math.pi + index * 0.5) * 40;

        final opacity = (math.sin(progress * math.pi) * 0.5 + 0.2).clamp(
          0.0,
          0.7,
        );
        final scale = (0.5 + math.sin(progress * 2 * math.pi) * 0.3).clamp(
          0.2,
          1.0,
        );

        return Positioned(
          left: x.clamp(0.0, size.width),
          top: y.clamp(0.0, size.height),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 3 + (index % 3),
                height: 3 + (index % 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
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

  Widget _buildFloatingOrb(int index, Color color) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.33) % 1.0;
        final size = MediaQuery.of(context).size;

        // Larger, slower moving orbs
        final x = (size.width * 0.8 * progress + index * 100) % size.width;
        final y =
            size.height * 0.3 +
            math.sin(progress * math.pi + index * 2) * size.height * 0.4;

        final opacity = (0.6 - progress * 0.4).clamp(0.0, 0.4);
        final scale = (1.0 - progress * 0.5).clamp(0.1, 1.0);

        return Positioned(
          left: x.clamp(0.0, size.width),
          top: y.clamp(0.0, size.height),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 60 + index * 20,
                height: 60 + index * 20,
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
    required Color secondaryColor,
    required bool useDynamicColors,
    required ColorScheme scheme,
  }) {
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
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: primaryColor,
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
                      'Personal Collection',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'My Playlist',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: headingColor,
                        letterSpacing: -0.5,
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
    required Color secondaryColor,
    required int songCount,
    required bool useDynamicColors,
    required ColorScheme scheme,
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
                          : const Color(0xFF6366f1).withOpacity(0.25),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.queue_music,
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
                      'Songs in your playlist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (songCount > 0) ...[
                GestureDetector(
                  onTap: () {
                    // Show confirmation dialog before clearing
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1a1a2e),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Clear Playlist',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to remove all songs from your playlist?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: customColorsEnabled
                                      ? primaryColor
                                      : const Color(0xFF6366f1),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                final playlistBox = Hive.box<PlaylistSong>(
                                  'playlistSongs',
                                );
                                playlistBox.clear();
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playPlaylistSong(
    PlaylistSong song,
    int index,
    List<PlaylistSong> playlistSongs,
  ) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);

    try {
      playerState.setSongLoading(true);
      if (song.downloadUrl != null && song.downloadUrl!.isNotEmpty) {
        await audioPlayer.pause();
        await audioPlayer.stop();
        final sources = playlistSongs
            .map(
              (s) => AudioSource.uri(
                Uri.parse(s.downloadUrl ?? ''),
                tag: MediaItem(
                  id: s.id,
                  album: '',
                  title: s.title,
                  artist: s.artist,
                  artUri: s.imageUrl.isNotEmpty
                      ? Uri.parse(s.imageUrl)
                      : (s.downloadUrl != null
                            ? Uri.parse(s.downloadUrl!)
                            : null),
                ),
              ),
            )
            .toList();
        final playlistSource = ConcatenatingAudioSource(children: sources);
        List<Map<String, dynamic>> playlist = playlistSongs
            .map(
              (s) => {
                'id': s.id,
                'name': s.title,
                'primaryArtists': s.artist,
                'image': s.imageUrl,
                'downloadUrl':
                    (s.downloadUrl is List &&
                        (s.downloadUrl != null) &&
                        (s.downloadUrl as List).isNotEmpty)
                    ? ((s.downloadUrl as List).first is Map
                          ? (s.downloadUrl as List).first['url']
                          : null)
                    : s.downloadUrl,
              },
            )
            .toList();
        playerState.setPlaylist(playlist);
        playerState.setSongIndex(index);
        playerState.setSong(playlist[index]);
        playerState.setCurrentContext("playlist");
        await audioPlayer.setAudioSource(playlistSource, initialIndex: index);
        await audioPlayer.play();
        playerState.setPlaying(true);
      } else {
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No audio URL available for this song.'),
              backgroundColor: Colors.red.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing song: $e'),
            backgroundColor: Colors.red.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
    playerState.setSongLoading(false);
    if (mounted && !_isDisposed) setState(() {});
  }

  void _openMusicPlayer(
    PlaylistSong song,
    int index,
    List<PlaylistSong> playlistSongs,
  ) async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);

    final isCurrentSong =
        playerState.currentSong != null &&
        playerState.currentSong!['id'] == song.id &&
        playerState.currentContext == "playlist";

    if (!isCurrentSong) {
      playerState.setSongLoading(true);
      await _playPlaylistSong(song, index, playlistSongs);
    }

    Navigator.of(context)
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
                            final currentIndex = playlistSongs.indexWhere(
                              (s) => s.id == song.id,
                            );
                            if (currentIndex != -1 &&
                                currentIndex < playlistSongs.length - 1) {
                              await _playPlaylistSong(
                                playlistSongs[currentIndex + 1],
                                currentIndex + 1,
                                playlistSongs,
                              );
                            }
                          },
                          onPrevious: () async {
                            final currentIndex = playlistSongs.indexWhere(
                              (s) => s.id == song.id,
                            );
                            if (currentIndex > 0) {
                              await _playPlaylistSong(
                                playlistSongs[currentIndex - 1],
                                currentIndex - 1,
                                playlistSongs,
                              );
                            }
                          },
                          onJumpToSong: (jumpIndex) async {
                            if (jumpIndex >= 0 &&
                                jumpIndex < playlistSongs.length) {
                              await _playPlaylistSong(
                                playlistSongs[jumpIndex],
                                jumpIndex,
                                playlistSongs,
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

  Widget _buildSongCard(
    PlaylistSong song,
    int index,
    List<PlaylistSong> playlistSongs,
    bool isCurrentSong,
    bool isPlaying,
    bool isLoading,
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
    VoidCallback onDelete,
    bool useDynamicColors,
    ColorScheme scheme,
  ) {
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
    final shouldShowPause =
        isCurrentSong && isPlaying && playerState.currentContext == "playlist";
    final showLoader =
        isCurrentSong && isLoading && playerState.currentContext == "playlist";

    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        // Calculate animation progress for this specific card
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isCurrentSong
                        ? [
                            primaryColor.withOpacity(0.15),
                            primaryColor.withOpacity(0.05),
                          ]
                        : [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03),
                          ],
                  ),
                  border: Border.all(
                    color: isCurrentSong
                        ? primaryColor.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCurrentSong
                          ? primaryColor.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openMusicPlayer(song, index, playlistSongs),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Album art with entrance animation
                          _buildAlbumArt(
                            song,
                            index,
                            isCurrentSong,
                            customColorsEnabled,
                            primaryColor,
                            secondaryColor,
                            animationProgress,
                          ),
                          const SizedBox(width: 12),

                          // Song information
                          Expanded(
                            child: _buildSongInfo(
                              song,
                              isCurrentSong,
                              isPlaying,
                              primaryColor,
                            ),
                          ),

                          // Controls
                          _buildControls(
                            song,
                            index,
                            playlistSongs,
                            isCurrentSong,
                            shouldShowPause,
                            showLoader,
                            customColorsEnabled,
                            primaryColor,
                            secondaryColor,
                            onDelete,
                            audioPlayer,
                            animationProgress,
                            useDynamicColors,
                            scheme,
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

  Widget _buildAlbumArt(
    PlaylistSong song,
    int index,
    bool isCurrentSong,
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
    double animationProgress,
  ) {
    return Hero(
      tag: 'album_art_${song.id}_$index',
      child: Transform.rotate(
        angle: ((1 - animationProgress) * 0.3).clamp(0.0, 1.0),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isCurrentSong
                    ? primaryColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: song.imageUrl.isNotEmpty
                ? Image.network(
                    song.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultArtwork(
                        customColorsEnabled,
                        primaryColor,
                        secondaryColor,
                      );
                    },
                  )
                : _buildDefaultArtwork(
                    customColorsEnabled,
                    primaryColor,
                    secondaryColor,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(
    PlaylistSong song,
    bool isCurrentSong,
    bool isPlaying,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: TextStyle(
            color: isCurrentSong ? primaryColor : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (isCurrentSong) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlaying ? Icons.volume_up : Icons.pause,
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
    );
  }

  Widget _buildControls(
    PlaylistSong song,
    int index,
    List<PlaylistSong> playlistSongs,
    bool isCurrentSong,
    bool shouldShowPause,
    bool showLoader,
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
    VoidCallback onDelete,
    AudioPlayer audioPlayer,
    double animationProgress,
    bool useDynamicColors,
    ColorScheme scheme,
  ) {
    final buttonColor = useDynamicColors
        ? scheme.primary
        : customColorsEnabled
        ? primaryColor
        : const Color(0xFF6366f1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/pause button with entrance animation
        Transform.scale(
          scale: (0.5 + (0.5 * animationProgress)).clamp(0.1, 1.0),
          child: GestureDetector(
            onTap: showLoader
                ? null
                : () async {
                    if (isCurrentSong && shouldShowPause) {
                      await audioPlayer.pause();
                      playerState.setPlaying(false);
                    } else if (isCurrentSong && !shouldShowPause) {
                      await audioPlayer.play();
                      playerState.setPlaying(true);
                    } else {
                      playerState.setSongLoading(true);
                      await _playPlaylistSong(song, index, playlistSongs);
                    }
                    if (mounted && !_isDisposed) setState(() {});
                  },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: customColorsEnabled
                        ? primaryColor.withOpacity(0.3)
                        : const Color(0xFF6366f1).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: showLoader
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      shouldShowPause
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: customColorsEnabled && primaryColor == Colors.white
                          ? secondaryColor
                          : Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Delete button with entrance animation
        Transform.scale(
          scale: (0.5 + (0.5 * animationProgress)).clamp(0.1, 1.0),
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
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
    );
  }

  Widget _buildDefaultArtwork(
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: customColorsEnabled
              ? [primaryColor.withOpacity(0.4), primaryColor.withOpacity(0.2)]
              : [
                  const Color(0xFF6366f1).withOpacity(0.4),
                  const Color(0xFF8b5cf6).withOpacity(0.2),
                ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: customColorsEnabled && primaryColor == Colors.white
            ? secondaryColor
            : Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildEmptyState({
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
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
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: customColorsEnabled
                          ? [
                              primaryColor.withOpacity(0.3),
                              primaryColor.withOpacity(0.1),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF6366f1).withOpacity(0.3),
                              const Color(0xFF8b5cf6).withOpacity(0.1),
                              Colors.transparent,
                            ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.library_music_outlined,
                    size: 60,
                    color: customColorsEnabled
                        ? primaryColor
                        : const Color(0xFF6366f1),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Your Playlist is Empty',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Start building your personal collection\nby adding your favorite songs!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: customColorsEnabled
                            ? [primaryColor, primaryColor.withOpacity(0.8)]
                            : [
                                const Color(0xFF6366f1),
                                const Color(0xFF8b5cf6),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: customColorsEnabled
                              ? primaryColor.withOpacity(0.4)
                              : const Color(0xFF6366f1).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.explore_rounded,
                          color:
                              customColorsEnabled &&
                                  primaryColor == Colors.white
                              ? secondaryColor
                              : Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Explore Music',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, _) {
        if (!Hive.isBoxOpen('playlistSongs')) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
              ),
            ),
          );
        }

        final playlistBox = Hive.box<PlaylistSong>('playlistSongs');
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
              : const Color(0xFF0f172a),
          body: Stack(
            children: [
              // Animated background with particles
              _buildAnimatedBackground(
                isPitchBlack: isPitchBlack,
                customColorsEnabled: customColorsEnabled,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                useDynamicColors: useDynamicColors,
                scheme: scheme,
              ),

              // Main content
              Column(
                children: [
                  _buildHeader(
                    customColorsEnabled: customColorsEnabled,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    useDynamicColors: useDynamicColors,
                    scheme: scheme,
                  ),
                  ValueListenableBuilder(
                    valueListenable: playlistBox.listenable(),
                    builder: (context, Box<PlaylistSong> box, _) {
                      return _buildStatsSection(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        songCount: box.values.length,
                        useDynamicColors: useDynamicColors,
                        scheme: scheme,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: playlistBox.listenable(),
                      builder: (context, Box<PlaylistSong> box, _) {
                        final songs = box.values.toList();

                        if (songs.isEmpty) {
                          return _buildEmptyState(
                            customColorsEnabled: customColorsEnabled,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            final isCurrentSong =
                                playerState.currentSong?['id'] == song.id &&
                                playerState.currentContext == "playlist";

                            return _buildSongCard(
                              song,
                              index,
                              songs,
                              isCurrentSong,
                              isCurrentSong && playerState.isPlaying,
                              isCurrentSong && playerState.isSongLoading,
                              customColorsEnabled,
                              primaryColor,
                              secondaryColor,
                              () => playlistBox.delete(song.id),
                              useDynamicColors,
                              scheme,
                            );
                          },
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
