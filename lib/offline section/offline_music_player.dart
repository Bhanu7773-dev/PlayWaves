import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';

class OfflineMusicPlayer extends StatefulWidget {
  final List<FileSystemEntity> playlist;
  final int initialIndex;
  const OfflineMusicPlayer({
    Key? key,
    required this.playlist,
    required this.audioPlayer,
    this.initialIndex = 0,
  }) : super(key: key);
  final AudioPlayer audioPlayer;

  @override
  State<OfflineMusicPlayer> createState() => _OfflineMusicPlayerState();
}

class _OfflineMusicPlayerState extends State<OfflineMusicPlayer>
    with TickerProviderStateMixin {
  late AnimationController _meteorsController;
  late AnimationController _likeController;
  late AnimationController _recordController;
  late AnimationController _waveController;
  late Animation<double> _likeScale;
  late Animation<double> _recordRotation;
  late Animation<double> _waveAnimation;

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isLiked = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.playlist.length - 1);
    _initializeAnimations();
    _setupAudioPlayer();
    _loadCurrentSong();
  }

  void _initializeAnimations() {
    _meteorsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _likeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _recordController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _likeScale = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_likeController);

    _recordRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _recordController, curve: Curves.linear));

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  void _setupAudioPlayer() {
    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });

        // Control animations based on playing state
        if (state.playing) {
          _recordController.repeat();
          _waveController.repeat(reverse: true);
        } else {
          _recordController.stop();
          _waveController.stop();
        }
      }
    });

    widget.audioPlayer.positionStream.listen((position) {
      if (mounted && !_isDragging) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    widget.audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      }
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _loadCurrentSong() async {
    if (widget.playlist.isEmpty) return;

    final file = widget.playlist[_currentIndex];
    final currentSource = widget.audioPlayer.audioSource;
    final isSameSource =
        currentSource is UriAudioSource &&
        currentSource.tag is MediaItem &&
        (currentSource.tag as MediaItem).id == file.path;

    if (!isSameSource) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget.audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.file(file.path),
            tag: MediaItem(
              id: file.path,
              album: 'Offline',
              title: _formatSongName(file.path),
              artist: 'Unknown Artist',
              artUri: null,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error loading song: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading song: $e'),
              backgroundColor: Colors.red.withOpacity(0.8),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _playPause() async {
    if (_isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      await widget.audioPlayer.play();
    }
  }

  void _playNext() {
    if (_currentIndex < widget.playlist.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadCurrentSong();
    } else {
      setState(() {
        _currentIndex = 0;
      });
      _loadCurrentSong();
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadCurrentSong();
    } else {
      setState(() {
        _currentIndex = widget.playlist.length - 1;
      });
      _loadCurrentSong();
    }
  }

  void _onSeek(double value) {
    final position = Duration(
      seconds: (value * _totalDuration.inSeconds).round(),
    );
    widget.audioPlayer.seek(position);
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

  String _extractArtistFromFilename(String filename) {
    final cleanName = filename.replaceAll('.mp3', '');
    if (cleanName.contains(' - ')) {
      final parts = cleanName.split(' - ');
      if (parts.length >= 2) {
        return parts[0].trim();
      }
    }
    return 'Unknown Artist';
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      _likeController.forward(from: 0);
    } else {
      _likeController.reverse();
    }
  }

  @override
  void dispose() {
    _meteorsController.dispose();
    _likeController.dispose();
    _recordController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customColorsEnabled
        ? customTheme.primaryColor
        : const Color(0xFFff7d78);

    if (widget.playlist.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          color: isPitchBlack ? Colors.black : customTheme.secondaryColor,
        ),
        child: const Center(
          child: Text(
            'No songs available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final currentFile = widget.playlist[_currentIndex];
    final songTitle = _formatSongName(currentFile.path);
    final artistName = _extractArtistFromFilename(
      currentFile.path.split(Platform.pathSeparator).last,
    );

    final double progress = _totalDuration.inSeconds > 0
        ? (_currentPosition.inSeconds / _totalDuration.inSeconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final double displayProgress = _isDragging ? _dragValue : progress;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: isPitchBlack
            ? Colors.black
            : customColorsEnabled
            ? customTheme.secondaryColor
            : const Color(0xFF0F0F23),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              _buildAnimatedBackground(isPitchBlack: isPitchBlack),
              SafeArea(
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildIconBox(
                            icon: Icons.keyboard_arrow_down,
                            onPressed: () => Navigator.pop(context),
                          ),
                          customColorsEnabled
                              ? Text(
                                  'Now Playing',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                )
                              : ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFFff7d78),
                                          Color(0xFF9c27b0),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Now Playing',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          _buildIconBox(
                            icon: Icons.queue_music,
                            onPressed: () => _showPlaylistQueue(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Vinyl Record with Audio Waveform
                    _buildVinylRecordWithWaveform(
                      customColorsEnabled,
                      primaryColor,
                    ),

                    const SizedBox(height: 48),

                    // Song Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            songTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                artistName,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _toggleLike,
                                child: AnimatedBuilder(
                                  animation: _likeController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isLiked ? _likeScale.value : 1.0,
                                      child: _isLiked
                                          ? (customColorsEnabled
                                                ? Icon(
                                                    Icons.favorite,
                                                    color: primaryColor,
                                                    size: 28,
                                                  )
                                                : ShaderMask(
                                                    shaderCallback: (Rect bounds) {
                                                      return const LinearGradient(
                                                        colors: [
                                                          Color(0xFFff7d78),
                                                          Color(0xFF9c27b0),
                                                        ],
                                                      ).createShader(bounds);
                                                    },
                                                    child: const Icon(
                                                      Icons.favorite,
                                                      color: Colors.white,
                                                      size: 28,
                                                    ),
                                                  ))
                                          : const Icon(
                                              Icons.favorite_border,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Progress Bar and Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress Bar
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              activeTrackColor: primaryColor,
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                              thumbColor: Colors.white,
                              overlayColor: primaryColor.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: displayProgress.clamp(0.0, 1.0),
                              min: 0.0,
                              max: 1.0,
                              onChangeStart: (value) {
                                setState(() {
                                  _isDragging = true;
                                  _dragValue = value;
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  _dragValue = value;
                                });
                              },
                              onChangeEnd: (value) {
                                setState(() {
                                  _isDragging = false;
                                });
                                _onSeek(value.clamp(0.0, 1.0));
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Time Labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                  _isDragging
                                      ? Duration(
                                          seconds:
                                              (_dragValue *
                                                      _totalDuration.inSeconds)
                                                  .round(),
                                        )
                                      : _currentPosition,
                                ),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Control Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildIconBox(
                            icon: Icons.skip_previous,
                            size: 32,
                            onPressed: _playPrevious,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: customColorsEnabled ? primaryColor : null,
                              gradient: !customColorsEnabled
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFff7d78),
                                        Color(0xFF9c27b0),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: IconButton(
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                              onPressed: _isLoading ? null : _playPause,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          _buildIconBox(
                            icon: Icons.skip_next,
                            size: 32,
                            onPressed: _playNext,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVinylRecordWithWaveform(
    bool customColorsEnabled,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedBuilder(
          animation: _recordRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _recordRotation.value * 2 * math.pi,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.black87,
                      Colors.black54,
                      Colors.black87,
                      Colors.black,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: customColorsEnabled
                          ? primaryColor.withOpacity(0.3)
                          : const Color(0xFFff7d78).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Outer ring (record edge)
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    ),

                    // Vinyl grooves (concentric circles)
                    ...List.generate(12, (index) {
                      final double size = 0.95 - (index * 0.065);
                      return Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7 * size,
                          height:
                              MediaQuery.of(context).size.width * 0.7 * size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.12),
                              width: 0.5,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Audio waveform pattern on the record
                    CustomPaint(
                      size: Size.infinite,
                      painter: WaveformPainter(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                        isPlaying: _isPlaying,
                        waveAnimation: _waveAnimation,
                      ),
                    ),

                    // Reflective highlights
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                            Colors.white.withOpacity(0.03),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Simple record label (center) - clean with no icon or text
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.black87,
                              Colors.black54,
                              Colors.black,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Label ring patterns only
                            ...List.generate(3, (index) {
                              final double size = 0.8 - (index * 0.15);
                              return Center(
                                child: Container(
                                  width: 80 * size,
                                  height: 80 * size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // Center hole
                    Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black87,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground({required bool isPitchBlack}) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;

    return Container(
      decoration: isPitchBlack
          ? const BoxDecoration(color: Colors.black)
          : customColorsEnabled
          ? BoxDecoration(color: customTheme.secondaryColor)
          : const BoxDecoration(
              gradient: LinearGradient(
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
            ),
      child: Stack(
        children: [
          ...List.generate(
            50,
            (index) => _buildStaticStar(index, isPitchBlack: isPitchBlack),
          ),
          ...List.generate(
            15,
            (index) => _buildMeteor(index, isPitchBlack: isPitchBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticStar(int index, {required bool isPitchBlack}) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;

    final List<Color> starColors = [
      Colors.white.withOpacity(0.8),
      Colors.blue.shade100.withOpacity(0.6),
      Colors.purple.shade100.withOpacity(0.5),
      const Color(0xFFFFE5B4).withOpacity(0.7),
    ];

    final starColor = customColorsEnabled
        ? customTheme.primaryColor.withOpacity(0.6)
        : starColors[index % starColors.length];

    return Positioned(
      top: (index * 37.0) % MediaQuery.of(context).size.height,
      left: (index * 73.0) % MediaQuery.of(context).size.width,
      child: Opacity(
        opacity: isPitchBlack ? 0 : (0.3 + (index % 3) * 0.2),
        child: Container(
          width: 1.5 + (index % 3) * 0.5,
          height: 1.5 + (index % 3) * 0.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: starColor,
            boxShadow: [
              BoxShadow(
                color: starColor.withOpacity(0.5),
                blurRadius: 2,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeteor(int index, {required bool isPitchBlack}) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;

    final List<Color> meteorColors = [
      const Color(0xFFFFE5B4),
      const Color(0xFFB8E6FF),
      const Color(0xFFE6B8FF),
      Colors.white,
    ];

    final meteorColor = customColorsEnabled
        ? customTheme.primaryColor
        : meteorColors[index % meteorColors.length];

    return AnimatedBuilder(
      animation: _meteorsController,
      builder: (context, child) {
        final double progress = _meteorsController.value;
        final double staggeredProgress = ((progress + (index * 0.15)) % 1.0)
            .clamp(0.0, 1.0);

        return Positioned(
          top: (index * 80.0) % MediaQuery.of(context).size.height,
          left: (index * 120.0) % MediaQuery.of(context).size.width,
          child: Transform.translate(
            offset: Offset(
              staggeredProgress * 150 - 75,
              staggeredProgress * 150 - 75,
            ),
            child: Opacity(
              opacity: isPitchBlack ? 0 : (1.0 - staggeredProgress) * 0.8,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: meteorColor,
                  boxShadow: [
                    BoxShadow(
                      color: meteorColor.withOpacity(0.6),
                      blurRadius: 8,
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

  Widget _buildIconBox({
    required IconData icon,
    double size = 28,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showPlaylistQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[900]!, Colors.grey[850]!],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      'Playlist Queue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.playlist.length} songs',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.playlist.length,
                      itemBuilder: (context, index) {
                        final file = widget.playlist[index];
                        final songName = _formatSongName(file.path);
                        final artistName = _extractArtistFromFilename(
                          file.path.split(Platform.pathSeparator).last,
                        );
                        final isCurrentSong = index == _currentIndex;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isCurrentSong
                                ? Colors.white.withOpacity(0.1)
                                : Colors.transparent,
                            border: isCurrentSong
                                ? Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  )
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: isCurrentSong
                                      ? [
                                          const Color(0xFFff7d78),
                                          const Color(0xFF9c27b0),
                                        ]
                                      : [Colors.grey[800]!, Colors.grey[700]!],
                                ),
                              ),
                              child: Icon(
                                isCurrentSong
                                    ? Icons.graphic_eq
                                    : Icons.music_note,
                                color: Colors.white,
                                size: isCurrentSong ? 24 : 20,
                              ),
                            ),
                            title: Text(
                              songName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isCurrentSong
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              artistName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isCurrentSong
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                    child: Text(
                                      'Playing',
                                      style: TextStyle(
                                        color: Colors.green.shade300,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                            onTap: () {
                              if (_currentIndex != index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                                _loadCurrentSong();
                              }
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Custom painter for audio waveform pattern with increased height
class WaveformPainter extends CustomPainter {
  final bool customColorsEnabled;
  final Color primaryColor;
  final bool isPlaying;
  final Animation<double> waveAnimation;

  WaveformPainter({
    required this.customColorsEnabled,
    required this.primaryColor,
    required this.isPlaying,
    required this.waveAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth =
          2.0 // Slightly thicker bars
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        size.width * 0.35; // Increased from 0.3 to 0.35 for taller bars
    final minRadius =
        size.width * 0.12; // Decreased from 0.15 to 0.12 for more space

    // Generate waveform data
    final waveformData = List.generate(100, (index) {
      // Reduced from 120 to 100 for better spacing
      final baseHeight =
          0.4 + math.sin(index * 0.6) * 0.3; // Increased base height
      final animationOffset = isPlaying ? waveAnimation.value * 2 * math.pi : 0;
      final dynamicHeight =
          baseHeight +
          math.sin(index * 0.9 + animationOffset) * 0.25; // Increased variation
      return dynamicHeight.clamp(0.2, 1.0); // Increased minimum height
    });

    // Draw waveform bars in circular pattern
    for (int i = 0; i < waveformData.length; i++) {
      final angle = (i * 2 * math.pi) / waveformData.length;
      final barHeight = waveformData[i] * (maxRadius - minRadius);

      final startRadius = minRadius;
      final endRadius = minRadius + barHeight;

      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );

      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );

      // Color gradient based on height and position
      final intensity = barHeight / (maxRadius - minRadius);
      paint.color = customColorsEnabled
          ? primaryColor.withOpacity(0.5 + intensity * 0.4) // Increased opacity
          : Color.lerp(
              const Color(0xFFff7d78).withOpacity(0.4),
              const Color(0xFF9c27b0).withOpacity(0.8),
              intensity,
            )!;

      canvas.drawLine(start, end, paint);
    }

    // Draw inner and outer circle guides with reduced opacity
    paint
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, minRadius, paint);
    canvas.drawCircle(center, maxRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
