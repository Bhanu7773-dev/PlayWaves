import 'dart:math';
import 'package:flutter/material.dart';

/// A custom loader inspired by the Apple Siri waveform animation.
/// Waves animate smoothly, with gradient colors and a "voicey" look.
/// Example usage:
///   SiriWaveLoader(
///     colors: [Colors.blueAccent, Colors.purpleAccent, Colors.pinkAccent],
///     width: 120,
///     height: 60,
///     waveCount: 2,
///     amplitude: 1.0,
///   )
class SiriWaveLoader extends StatefulWidget {
  final List<Color> colors;
  final double width;
  final double height;
  final int waveCount;
  final double amplitude; // 0.0 - 1.0, for "voice" effect

  const SiriWaveLoader({
    Key? key,
    this.colors = const [
      Color(0xFF48C6EF),
      Color(0xFF6F86D6),
      Color(0xFFF7971E),
      Color(0xFFFF5858),
    ],
    this.width = 120,
    this.height = 60,
    this.waveCount = 2,
    this.amplitude = 1.0,
  }) : super(key: key);

  @override
  State<SiriWaveLoader> createState() => _SiriWaveLoaderState();
}

class _SiriWaveLoaderState extends State<SiriWaveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _SiriWavePainter(
            progress: _controller.value,
            colors: widget.colors,
            waveCount: widget.waveCount,
            amplitude: widget.amplitude,
          ),
        ),
      ),
    );
  }
}

class _SiriWavePainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final int waveCount;
  final double amplitude;

  _SiriWavePainter({
    required this.progress,
    required this.colors,
    required this.waveCount,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final double baseAmplitude = centerY * 0.6 * amplitude;
    final double wavelength = size.width * 0.9;
    final double speed = progress * 2 * pi;

    for (int i = 0; i < waveCount; i++) {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 + i * 1.2
        ..color = colors[i % colors.length].withOpacity(0.75 - (i * 0.15));

      final path = Path();
      final double wavePhase = speed + pi * i; // phase offset per wave
      final double waveAmp = baseAmplitude * (1 - i * 0.29);

      for (double x = 0; x <= size.width; x += 1) {
        // The Siri wave uses a "rounded" sine, often with more harmonics.
        // This formula mimics that look: two overlapped sine waves
        double y =
            centerY +
            waveAmp *
                sin((2 * pi * x / wavelength) + wavePhase) *
                (1 - 0.4 * cos((2 * pi * x / wavelength) + wavePhase));
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Gradient overlay for the wave
      final gradient = LinearGradient(
        colors: [
          colors[i % colors.length].withOpacity(0.7),
          colors[(i + 1) % colors.length].withOpacity(0.7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      paint.shader = gradient;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiriWavePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colors != colors ||
      oldDelegate.waveCount != waveCount ||
      oldDelegate.amplitude != amplitude;
}
