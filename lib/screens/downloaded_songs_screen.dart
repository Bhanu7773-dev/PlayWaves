import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';
import '../offline section/offline_music_player.dart';

class DownloadedSongsScreen extends StatefulWidget {
  const DownloadedSongsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadedSongsScreen> createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen>
    with TickerProviderStateMixin {
  List<FileSystemEntity> _songs = [];
  bool _loading = true;
  late AudioPlayer _audioPlayer;
  int? _currentIndex;

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _particleController;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSongs();
    _startAnimations();
  }

  void _initializeAnimations() {
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
  }

  void _startAnimations() {
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _headerController.dispose();
    _particleController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    await Future.delayed(const Duration(milliseconds: 500));

    Directory? dir;
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      dir = dirs?.first;
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    if (dir != null) {
      final files = dir
          .listSync()
          .where((f) => f.path.toLowerCase().endsWith('.mp3'))
          .toList();

      if (mounted) {
        setState(() {
          _songs = files;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _playSong(int index) async {
    try {
      final songFile = _songs[index];
      final songPath = songFile.path;
      final songTitle = _formatSongName(songPath);
      final songArtist = "Unknown Artist";
      final mediaItem = MediaItem(
        id: songPath,
        album: 'Downloaded',
        title: songTitle,
        artist: songArtist,
        artUri: null,
      );
      final currentSource = _audioPlayer.audioSource;
      final isSameSource =
          currentSource is UriAudioSource &&
          currentSource.tag is MediaItem &&
          (currentSource.tag as MediaItem).id == songPath;
      if (!isSameSource) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.file(songPath), tag: mediaItem),
        );
        setState(() {
          _currentIndex = index;
        });
      }
      await _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing song: $e'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  void _pauseSong() async {
    await _audioPlayer.pause();
    setState(() {});
  }

  String _formatSongName(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final nameWithoutExtension = fileName.replaceAll('.mp3', '');

    String cleanName = nameWithoutExtension
        .replaceAll(RegExp(r'^\d+\.'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    return cleanName
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word,
        )
        .join(' ');
  }

  String _formatFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
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
            15,
            (index) => _buildFloatingParticle(
              index,
              customColorsEnabled ? primaryColor : const Color(0xFF6366f1),
            ),
          ),
          // Slow moving orbs
          ...List.generate(
            3,
            (index) => _buildFloatingOrb(
              index,
              customColorsEnabled ? primaryColor : const Color(0xFF8b5cf6),
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
                      'Offline Music',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Downloaded Songs',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: customColorsEnabled
                                  ? primaryColor
                                  : const Color(0xFF6366f1),
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
                          : const Color(0xFF6366f1).withOpacity(0.25),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.download_done_rounded,
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
                      'Available offline',
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
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: customColorsEnabled
                        ? primaryColor.withOpacity(0.15)
                        : const Color(0xFF6366f1).withOpacity(0.15),
                  ),
                  child: Icon(
                    Icons.offline_bolt_rounded,
                    color: customColorsEnabled
                        ? primaryColor
                        : const Color(0xFF6366f1),
                    size: 18,
                  ),
                ),
              ],
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
                    Icons.download_outlined,
                    size: 60,
                    color: customColorsEnabled
                        ? primaryColor
                        : const Color(0xFF6366f1),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'No Downloaded Songs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Download songs to listen offline\nwithout internet connection',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongsList({
    required bool customColorsEnabled,
    required Color primaryColor,
  }) {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, playerStateSnapshot) {
        return StreamBuilder<int?>(
          stream: _audioPlayer.currentIndexStream,
          builder: (context, indexSnapshot) {
            final playing = playerStateSnapshot.data?.playing ?? false;
            final currentIndex = indexSnapshot.data;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              physics: const BouncingScrollPhysics(),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final isPlaying = currentIndex == index && playing;

                return AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    final animationProgress = Curves.easeOutBack.transform(
                      (_cardController.value - (index * 0.08)).clamp(0.0, 1.0),
                    );

                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - animationProgress)),
                      child: Transform.scale(
                        scale: (0.9 + (0.1 * animationProgress)).clamp(
                          0.1,
                          1.0,
                        ),
                        child: Opacity(
                          opacity: animationProgress.clamp(0.0, 1.0),
                          child: _buildSongCard(
                            index,
                            customColorsEnabled,
                            primaryColor,
                            isPlaying,
                            animationProgress,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSongCard(
    int index,
    bool customColorsEnabled,
    Color primaryColor,
    bool isPlaying,
    double animationProgress,
  ) {
    final file = _songs[index];
    final songName = _formatSongName(file.path);
    final fileSize = _formatFileSize(File(file.path));

    final playlistCardMargin = const EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 4,
    );
    final playlistCardPadding = const EdgeInsets.all(12);
    final albumArtSize = 50.0;
    final borderRadius = BorderRadius.circular(16);
    final albumArtRadius = BorderRadius.circular(12);
    final gradientColors = isPlaying
        ? customColorsEnabled
              ? [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.05)]
              : [
                  const Color(0xFF6366f1).withOpacity(0.15),
                  const Color(0xFF8b5cf6).withOpacity(0.05),
                ]
        : [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)];
    final borderColor = isPlaying
        ? customColorsEnabled
              ? primaryColor.withOpacity(0.3)
              : const Color(0xFF6366f1).withOpacity(0.3)
        : Colors.white.withOpacity(0.1);
    final boxShadow = [
      BoxShadow(
        color: isPlaying
            ? customColorsEnabled
                  ? primaryColor.withOpacity(0.2)
                  : const Color(0xFF6366f1).withOpacity(0.2)
            : Colors.black.withOpacity(0.1),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ];
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
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
                  border: Border.all(
                    color: borderColor,
                    width: isPlaying ? 1.2 : 0.8,
                  ),
                  boxShadow: boxShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.88,
                            minChildSize: 0.56,
                            maxChildSize: 0.95,
                            expand: false,
                            builder: (_, scrollController) =>
                                OfflineMusicPlayer(
                                  playlist: _songs,
                                  initialIndex: index,
                                  audioPlayer: _audioPlayer,
                                ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: playlistCardPadding,
                      child: Row(
                        children: [
                          Transform.rotate(
                            angle: ((1 - animationProgress) * 0.2).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Container(
                              width: albumArtSize,
                              height: albumArtSize,
                              decoration: BoxDecoration(
                                borderRadius: albumArtRadius,
                                gradient: LinearGradient(
                                  colors: isPlaying
                                      ? customColorsEnabled
                                            ? [
                                                primaryColor.withOpacity(0.25),
                                                primaryColor.withOpacity(0.08),
                                              ]
                                            : [
                                                const Color(
                                                  0xFF6366f1,
                                                ).withOpacity(0.25),
                                                const Color(
                                                  0xFF8b5cf6,
                                                ).withOpacity(0.15),
                                              ]
                                      : [
                                          Colors.white.withOpacity(0.15),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                ),
                              ),
                              child: Icon(
                                Icons.music_note_rounded,
                                color: isPlaying
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  songName,
                                  style: TextStyle(
                                    color: isPlaying
                                        ? customColorsEnabled
                                              ? primaryColor
                                              : const Color(0xFF6366f1)
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.storage_rounded,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        fileSize,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
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
                          const SizedBox(width: 8),
                          _buildPlayButton(
                            index,
                            isPlaying,
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
    int index,
    bool isPlaying,
    bool customColorsEnabled,
    Color primaryColor,
    double animationProgress,
  ) {
    return Transform.scale(
      scale: (0.6 + (0.4 * animationProgress)).clamp(0.1, 1.0),
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
                  : const Color(0xFF6366f1).withOpacity(0.35),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isPlaying ? _pauseSong : () => _playSong(index),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
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
    final primaryColor = customColorsEnabled
        ? customTheme.primaryColor
        : const Color(0xFF6366f1);
    final secondaryColor = customColorsEnabled
        ? customTheme.secondaryColor
        : const Color(0xFF1e293b);

    // Assign global AudioPlayer from Provider
    _audioPlayer = Provider.of<AudioPlayer>(context, listen: false);

    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : const Color(0xFF0f172a),
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
                songCount: _songs.length,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            customColorsEnabled
                                ? primaryColor
                                : const Color(0xFF6366f1),
                          ),
                        ),
                      )
                    : _songs.isEmpty
                    ? _buildEmptyState(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                      )
                    : _buildSongsList(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
