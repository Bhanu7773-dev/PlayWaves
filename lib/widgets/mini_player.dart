import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/custom_theme_provider.dart';

class RippleFlowEffect extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const RippleFlowEffect({
    Key? key,
    required this.isPlaying,
    required this.color,
  }) : super(key: key);

  @override
  State<RippleFlowEffect> createState() => _RippleFlowEffectState();
}

class _RippleFlowEffectState extends State<RippleFlowEffect>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late AnimationController _controller4;
  late AnimationController _controller5;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;
  late Animation<double> _animation4;
  late Animation<double> _animation5;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _controller4 = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    _controller5 = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    _animation1 = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller1, curve: Curves.easeOut));
    _animation2 = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeOut));
    _animation3 = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller3, curve: Curves.easeOut));
    _animation4 = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller4, curve: Curves.easeOut));
    _animation5 = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller5, curve: Curves.easeOut));

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _controller1.repeat();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _controller3.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _controller4.repeat();
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) _controller5.repeat();
    });
  }

  void _stopAnimations() {
    _controller1.stop();
    _controller2.stop();
    _controller3.stop();
    _controller4.stop();
    _controller5.stop();
  }

  @override
  void didUpdateWidget(RippleFlowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    _controller5.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Provider.of<CustomThemeProvider>(context);
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _animation1,
        _animation2,
        _animation3,
        _animation4,
        _animation5,
      ]),
      builder: (context, child) {
        return CustomPaint(
          painter: RipplePainter(
            animation1: _animation1.value,
            animation2: _animation2.value,
            animation3: _animation3.value,
            animation4: _animation4.value,
            animation5: _animation5.value,
            color: customColorsEnabled ? primaryColor : null,
            gradient: customColorsEnabled
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class RipplePainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final double animation4;
  final double animation5;
  final Color? color;
  final LinearGradient? gradient;

  RipplePainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.animation4,
    required this.animation5,
    this.color,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * 0.08,
      size.height * 0.5,
    ); // Position even further left, just below album art
    final maxRadius = size.width * 0.9;

    for (final anim in [
      animation1,
      animation2,
      animation3,
      animation4,
      animation5,
    ]) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      if (color != null) {
        paint.color = color!.withOpacity((1 - anim) * 0.3);
      } else if (gradient != null) {
        final rect = Rect.fromCircle(center: center, radius: maxRadius * anim);
        paint.shader = gradient!.createShader(rect);
        paint.color = Colors.white.withOpacity((1 - anim) * 0.3);
      }
      if (anim > 0) {
        canvas.drawCircle(center, maxRadius * anim, paint);
      }
    }
  }

  void _drawRipple(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    Paint paint,
  ) {
    if (radius > 0) {
      paint.color = color;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MiniPlayer extends StatelessWidget {
  final Map<String, dynamic>? currentSong;
  final AudioPlayer audioPlayer;
  final bool isSongLoading;
  final VoidCallback? onPlayPause;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    required this.currentSong,
    required this.audioPlayer,
    this.isSongLoading = false,
    this.onPlayPause,
    this.onClose,
    this.onTap,
  });

  String _getArtistName(Map<String, dynamic>? song) {
    if (song == null) return 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        return artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['primaryArtists'] != null) {
      return song['primaryArtists'];
    } else if (song['subtitle'] != null) {
      return song['subtitle'];
    }
    return 'Unknown Artist';
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

  @override
  Widget build(BuildContext context) {
    if (currentSong == null) return const SizedBox.shrink();

    String artistName = _getArtistName(currentSong);
    String albumArtUrl = '';
    if (currentSong?['image'] != null) {
      albumArtUrl = _getBestImageUrl(currentSong!['image']) ?? '';
    }
    final songTitle =
        currentSong?['name'] ?? currentSong?['title'] ?? 'Unknown';

    // Use the SAME Hero tags as MusicPlayerPage for animation!
    final String heroAlbumArtTag =
        'album_art_${currentSong?['id'] ?? songTitle}_${artistName}';
    final String heroTitleTag =
        'song_title_${currentSong?['id'] ?? songTitle}_${artistName}';
    final String heroArtistTag =
        'artist_name_${currentSong?['id'] ?? songTitle}_${artistName}';

    final customTheme = Provider.of<CustomThemeProvider>(context);
    final useCustom = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 21, 21, 21).withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Ripple effect background
              Positioned.fill(
                child: StreamBuilder<bool>(
                  stream: audioPlayer.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return RippleFlowEffect(
                      isPlaying: isPlaying,
                      color: useCustom ? primaryColor : const Color(0xFFff7d78),
                    );
                  },
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Album Art with Hero Animation (same tag as MusicPlayerPage)
                    Hero(
                      tag: heroAlbumArtTag,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: useCustom
                                  ? primaryColor.withOpacity(0.22)
                                  : const Color.fromARGB(
                                      255,
                                      19,
                                      19,
                                      19,
                                    ).withOpacity(1.0),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: albumArtUrl.isNotEmpty
                              ? Image.network(
                                  albumArtUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: useCustom
                                          ? primaryColor.withOpacity(0.18)
                                          : Colors.grey[800],
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: useCustom
                                      ? primaryColor.withOpacity(0.18)
                                      : Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Song Info with Hero Animation (same tags as MusicPlayerPage)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: heroTitleTag,
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                songTitle,
                                style: TextStyle(
                                  color: useCustom
                                      ? primaryColor
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Hero(
                            tag: heroArtistTag,
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                artistName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Control buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder<bool>(
                          stream: audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              onPressed: onPlayPause,
                              icon: useCustom
                                  ? Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: primaryColor,
                                      size: 28,
                                    )
                                  : ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return const LinearGradient(
                                          colors: [
                                            Color(0xFF6366f1),
                                            Color(0xFF8b5cf6),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds);
                                      },
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                              padding: const EdgeInsets.all(4),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4),
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
}
