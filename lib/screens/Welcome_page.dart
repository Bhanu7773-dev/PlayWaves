import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'homepage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _meteorsController;
  late AnimationController _loginCardController;
  bool _showLoginCard = false;
  bool _dismissalThresholdCrossed = false;

  @override
  void initState() {
    super.initState();
    _meteorsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _loginCardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _meteorsController.dispose();
    _loginCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use your vibrant dark gradient background here:
      body: Stack(
        children: [
          _buildAnimatedBackground(context),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Heading
                  Transform.translate(
                    offset: const Offset(0, -60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        children: [
                          Text(
                            'Welcome to',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.8),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PlayWaves',
                            style: TextStyle(
                              fontFamily: 'Wednesday',
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Lottie Animation
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: SizedBox(
                      height: 400,
                      child: Lottie.asset(
                        'assets/lottie/musicbot.json',
                        repeat: true,
                        animate: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Start Journey button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366f1).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () {
                          setState(() {
                            _showLoginCard = true;
                            _dismissalThresholdCrossed =
                                false; // Reset threshold
                          });
                          _loginCardController.forward();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Start Journey',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Login Card
          if (_showLoginCard)
            AnimatedBuilder(
              animation: _loginCardController,
              builder: (context, child) {
                return Positioned(
                  bottom: -300 + (_loginCardController.value * 300),
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      // Allow dragging when the card is visible
                      if (_loginCardController.value > 0.1) {
                        // Calculate new position based on drag
                        final newValue =
                            _loginCardController.value -
                            (details.delta.dy / 200);
                        final clampedValue = newValue.clamp(0.0, 1.0);
                        _loginCardController.value = clampedValue;

                        // Track if user has crossed the dismissal threshold (30%)
                        if (clampedValue < 0.7) {
                          _dismissalThresholdCrossed = true;
                        } else if (clampedValue > 0.8) {
                          // Reset if they drag back up past 80%
                          _dismissalThresholdCrossed = false;
                        }
                      }
                    },
                    onVerticalDragEnd: (details) {
                      // Only dismiss if threshold was crossed AND user is still below it
                      if (_dismissalThresholdCrossed &&
                          _loginCardController.value < 0.7) {
                        _loginCardController.reverse().then((_) {
                          if (mounted) {
                            setState(() {
                              _showLoginCard = false;
                              _dismissalThresholdCrossed =
                                  false; // Reset for next time
                            });
                          }
                        });
                      } else {
                        // Snap back to fully open and reset threshold
                        _loginCardController.forward();
                        _dismissalThresholdCrossed = false;
                      }
                    },
                    child: Container(
                      height: 300,
                      decoration: const BoxDecoration(
                        color: Colors
                            .white, // Changed from dark grey to white for better visibility
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Scattered PNG images as wallpaper
                          ..._buildScatteredImages(),
                          // Bat decorations
                          ..._buildBatDecorations(),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                // Drag handle
                                Container(
                                  width: 50,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(
                                      0.3,
                                    ), // Changed to black for visibility on white background
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Welcome text
                                const Text(
                                  'Welcome to PlayWaves',
                                  style: TextStyle(
                                    fontSize:
                                        32, // Increased from 24 to 32 for more impact
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .black, // Changed to black for visibility on white background
                                    fontFamily:
                                        'Wednesday', // Added Wednesday font
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to sync your music across devices',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withOpacity(
                                      0.7,
                                    ), // Changed to black for visibility on white background
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                // Google Login Button
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366f1),
                                        Color(0xFF8b5cf6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6366f1,
                                        ).withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors
                                          .white, // Changed back to white as requested
                                      minimumSize: const Size.fromHeight(55),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement Google login
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const HomePage(),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.login,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Google Login',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 11,
                                ), // Reduced from 16 to 11 (removed 5px)
                                // Skip button
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const HomePage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Skip for now',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(
                                        0.7,
                                      ), // Changed to black for visibility on white background
                                      fontSize: 16,
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
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _buildBatDecorations() {
    return List.generate(8, (index) {
      final random = Random(index);
      return Positioned(
        left: random.nextDouble() * 300,
        top: 40 + random.nextDouble() * 200,
        child: Transform.rotate(
          angle: random.nextDouble() * 0.6 - 0.3,
          child: Opacity(
            opacity: 0.1 + random.nextDouble() * 0.1,
            child: CustomPaint(size: const Size(20, 12), painter: BatPainter()),
          ),
        ),
      );
    });
  }

  List<Widget> _buildScatteredImages() {
    final images = [
      'assets/image/B1.png',
      'assets/image/B2.png',
      'assets/image/B3.png',
    ];

    // Reduced number of images and better spacing
    final positions = [
      // Top row - 3 images
      const Offset(50, 40),
      const Offset(160, 30),
      const Offset(270, 50),
      // Middle row - 3 images
      const Offset(30, 120),
      const Offset(180, 110),
      const Offset(290, 130),
      // Bottom row - 2 images
      const Offset(80, 200),
      const Offset(240, 190),
    ];

    return List.generate(positions.length, (index) {
      final random = Random(index + 100);
      final imageIndex = random.nextInt(images.length);
      final basePosition = positions[index];

      // Add small random offset for natural scattering (±20px)
      final left = basePosition.dx + (random.nextDouble() - 0.5) * 40;
      final top = basePosition.dy + (random.nextDouble() - 0.5) * 30;

      return Positioned(
        left: left.clamp(10, 280), // Ensure within bounds
        top: top.clamp(20, 240), // Ensure within bounds
        child: Transform.rotate(
          angle: random.nextDouble() * 0.8 - 0.4, // Random rotation
          child: Opacity(
            opacity:
                0.15 +
                random.nextDouble() * 0.15, // Low opacity for wallpaper effect
            child: Image.asset(
              images[imageIndex],
              width: 45 + random.nextDouble() * 25, // Slightly larger size
              height: 45 + random.nextDouble() * 25,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedBackground(BuildContext context) {
    // Colors similar to your music player background
    return Container(
      decoration: const BoxDecoration(
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
          ...List.generate(50, (index) => _buildStaticStar(index, context)),
          ...List.generate(15, (index) => _buildMeteor(index, context)),
        ],
      ),
    );
  }

  Widget _buildStaticStar(int index, BuildContext context) {
    final List<Color> starColors = [
      Colors.white.withOpacity(0.8),
      Colors.blue.shade100.withOpacity(0.6),
      Colors.purple.shade100.withOpacity(0.5),
      const Color(0xFFFFE5B4).withOpacity(0.7),
    ];
    final starColor = starColors[index % starColors.length];

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Positioned(
      top: (index * 37.0) % height,
      left: (index * 73.0) % width,
      child: Opacity(
        opacity: 0.3 + (index % 3) * 0.2,
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

  Widget _buildMeteor(int index, BuildContext context) {
    final List<Color> meteorColors = [
      const Color(0xFFFFE5B4),
      const Color(0xFFB8E6FF),
      const Color(0xFFE6B8FF),
      Colors.white,
    ];
    final meteorColor = meteorColors[index % meteorColors.length];

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _meteorsController,
      builder: (context, child) {
        final double progress = _meteorsController.value;
        final double staggeredProgress = ((progress + (index * 0.15)) % 1.0)
            .clamp(0.0, 1.0);
        return Positioned(
          top: (index * 80.0) % height,
          left: (index * 120.0) % width,
          child: Transform.translate(
            offset: Offset(
              staggeredProgress * 150 - 75,
              staggeredProgress * 150 - 75,
            ),
            child: Opacity(
              opacity: (1.0 - staggeredProgress) * 0.8,
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
}

class BatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();

    // Bat body
    final bodyX = size.width / 2;
    final bodyY = size.height * 0.6;
    canvas.drawCircle(Offset(bodyX, bodyY), 1.5, paint);

    // Left wing
    path.moveTo(bodyX - 1, bodyY);
    path.quadraticBezierTo(
      bodyX - size.width * 0.3,
      bodyY - size.height * 0.4,
      bodyX - size.width * 0.45,
      bodyY - size.height * 0.1,
    );
    path.quadraticBezierTo(
      bodyX - size.width * 0.35,
      bodyY + size.height * 0.1,
      bodyX - 1,
      bodyY,
    );

    // Right wing
    path.moveTo(bodyX + 1, bodyY);
    path.quadraticBezierTo(
      bodyX + size.width * 0.3,
      bodyY - size.height * 0.4,
      bodyX + size.width * 0.45,
      bodyY - size.height * 0.1,
    );
    path.quadraticBezierTo(
      bodyX + size.width * 0.35,
      bodyY + size.height * 0.1,
      bodyX + 1,
      bodyY,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
