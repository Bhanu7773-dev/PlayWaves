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
  late AnimationController _masterController;
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Use global AudioPlayer from Provider
    // Delay assignment until build to access context
    _initializeAnimations();
    _loadSongs();
    _startAnimations();
  }

  void _initializeAnimations() {
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _masterController, curve: Curves.easeOutBack),
        );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _masterController.forward();
    _waveController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _masterController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    // Do NOT dispose _audioPlayer here, so playback persists between screens
    super.dispose();
  }

  Future<void> _loadSongs() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Smooth loading

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

  @override
  Widget build(BuildContext context) {
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    final secondaryColor = customTheme.secondaryColor;
    // Assign global AudioPlayer from Provider
    _audioPlayer = Provider.of<AudioPlayer>(context, listen: false);

    return Scaffold(
      backgroundColor: isPitchBlack
          ? Colors.black
          : customColorsEnabled
          ? secondaryColor
          : const Color(0xFF0F0F23), // Same as music player
      body: Stack(
        children: [
          _buildAnimatedBackground(
            isPitchBlack,
            customColorsEnabled,
            primaryColor,
            secondaryColor,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(customColorsEnabled, primaryColor),
                    const SizedBox(height: 20),
                    _buildStatsCard(customColorsEnabled, primaryColor),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _loading
                          ? _buildLoadingState(
                              customColorsEnabled,
                              primaryColor,
                            )
                          : _songs.isEmpty
                          ? _buildEmptyState(customColorsEnabled, primaryColor)
                          : _buildSongsList(customColorsEnabled, primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(
    bool isPitchBlack,
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: isPitchBlack
                ? null
                : customColorsEnabled
                ? RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      secondaryColor,
                      secondaryColor.withOpacity(0.7),
                      Colors.black,
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F0F23),
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F0F23),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
            color: isPitchBlack ? Colors.black : null,
          ),
          child: Stack(
            children: [
              ...List.generate(8, (index) {
                final Color iconColor = customColorsEnabled
                    ? (index % 2 == 0 ? primaryColor : secondaryColor)
                    : const Color(0xFFff7d78);
                return _buildFloatingIcon(index, iconColor, isPitchBlack);
              }),
              ...List.generate(15, (index) {
                final double offsetX = (index * 67.3) % 400;
                final double offsetY = (index * 89.7) % 700;
                return _buildBackgroundDot(offsetX, offsetY, index);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingIcon(int index, Color iconColor, bool isPitchBlack) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        final double progress = _waveAnimation.value;
        final double staggeredProgress = ((progress + (index * 0.15)) % 1.0);

        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Positioned(
          top: (index * 90.0) % screenHeight,
          left: (index * 130.0) % screenWidth,
          child: Transform.translate(
            offset: Offset(
              math.sin(staggeredProgress * 2 * math.pi) * 30,
              math.cos(staggeredProgress * 2 * math.pi) * 20,
            ),
            child: Opacity(
              opacity: isPitchBlack ? 0 : 0.6,
              child: Icon(
                Icons.download_done,
                size: 24,
                color: iconColor.withOpacity(0.4),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundDot(double offsetX, double offsetY, int index) {
    final pulse =
        0.2 + math.sin(_pulseAnimation.value * 2 * math.pi + index * 0.5) * 0.3;

    return Positioned(
      left: offsetX,
      top: offsetY,
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(pulse.clamp(0.1, 0.5)),
        ),
      ),
    );
  }

  Widget _buildHeader(bool customColorsEnabled, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Downloaded',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                customColorsEnabled
                    ? Text(
                        'Music Library',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFff7d78),
                            Color(0xFF9c27b0),
                          ], // Changed to match music player
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Music Library',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
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
    );
  }

  Widget _buildStatsCard(bool customColorsEnabled, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: customColorsEnabled
                          ? [primaryColor, primaryColor.withOpacity(0.7)]
                          : const [
                              Color(0xFFff7d78),
                              Color(0xFF9c27b0),
                            ], // Changed to match music player
                    ),
                  ),
                  child: const Icon(
                    Icons.download_done,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_songs.length} Songs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Ready to play offline',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_songs.isNotEmpty)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + _pulseAnimation.value * 0.1,
                        child: Icon(
                          Icons.music_note,
                          color: customColorsEnabled
                              ? primaryColor
                              : const Color(
                                  0xFFff7d78,
                                ), // Changed to match music player
                          size: 24,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool customColorsEnabled, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + _pulseAnimation.value * 0.2,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: customColorsEnabled
                          ? [primaryColor, primaryColor.withOpacity(0.5)]
                          : const [
                              Color(0xFFff7d78),
                              Color(0xFF9c27b0),
                            ], // Changed to match music player
                    ),
                  ),
                  child: const Icon(
                    Icons.download_done,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Scanning for songs...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we find your music',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool customColorsEnabled, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.music_off,
                size: 60,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Songs Found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Download some music to your device\nto see them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList(bool customColorsEnabled, Color primaryColor) {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, playerStateSnapshot) {
        return StreamBuilder<int?>(
          stream: _audioPlayer.currentIndexStream,
          builder: (context, indexSnapshot) {
            final playing = playerStateSnapshot.data?.playing ?? false;
            final currentIndex = indexSnapshot.data;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final isPlaying = currentIndex == index && playing;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600 + (index * 50)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 30),
                        child: Opacity(
                          opacity: value,
                          child: _buildSongCard(
                            index,
                            customColorsEnabled,
                            primaryColor,
                            isPlayingOverride: isPlaying,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSongCard(
    int index,
    bool customColorsEnabled,
    Color primaryColor, {
    bool? isPlayingOverride,
  }) {
    final file = _songs[index];
    final isPlaying =
        isPlayingOverride ?? (_currentIndex == index && _audioPlayer.playing);
    final songName = _formatSongName(file.path);
    final fileSize = _formatFileSize(File(file.path));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isPlaying
              ? customColorsEnabled
                    ? [
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.05),
                      ]
                    : [
                        const Color(
                          0xFFff7d78,
                        ).withOpacity(0.15), // Changed to match music player
                        const Color(
                          0xFF9c27b0,
                        ).withOpacity(0.05), // Changed to match music player
                      ]
              : [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
        ),
        border: Border.all(
          color: isPlaying
              ? customColorsEnabled
                    ? primaryColor.withOpacity(0.3)
                    : const Color(0xFFff7d78).withOpacity(
                        0.3,
                      ) // Changed to match music player
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: isPlaying
                      ? customColorsEnabled
                            ? [primaryColor, primaryColor.withOpacity(0.7)]
                            : const [
                                Color(0xFFff7d78),
                                Color(0xFF9c27b0),
                              ] // Changed to match music player
                      : [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                ),
              ),
              child: Icon(Icons.music_note, color: Colors.white, size: 24),
            ),
            title: Text(
              songName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              fileSize,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
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
                    builder: (_, scrollController) => OfflineMusicPlayer(
                      playlist: _songs,
                      initialIndex: index,
                      audioPlayer: _audioPlayer,
                    ),
                  );
                },
              );
            },
            trailing: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isPlaying ? _pauseSong : () => _playSong(index),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPlaying
                        ? customColorsEnabled
                              ? [primaryColor, primaryColor.withOpacity(0.8)]
                              : const [
                                  Color(0xFFff7d78),
                                  Color(0xFF9c27b0),
                                ] // Changed to match music player
                        : [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
