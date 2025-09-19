import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'homepage.dart';
import '../services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _meteorsController;
  late AnimationController _loginCardController;
  late AnimationController _buttonAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonRotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _buttonColorAnimation;

  bool _showLoginCard = false;
  bool _dismissalThresholdCrossed = false;
  bool _isLoading = false;
  bool _controllersInitialized = false;
  final UserAuthService _authService = UserAuthService();

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

    // Button animation controller
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Scale animation for button press
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Subtle rotation animation
    _buttonRotationAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for glow effect
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Color animation for loading state
    _buttonColorAnimation =
        ColorTween(
          begin: const Color(0xFF6366f1),
          end: const Color(0xFF8b5cf6),
        ).animate(
          CurvedAnimation(
            parent: _buttonAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _meteorsController.dispose();
    _loginCardController.dispose();
    _buttonAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onButtonTapDown(TapDownDetails details) {
    _buttonAnimationController.forward();
  }

  void _onButtonTapUp(TapUpDetails details) {
    _buttonAnimationController.reverse();
  }

  void _onButtonTapCancel() {
    _buttonAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          if (_controllersInitialized) {
                            setState(() {
                              _showLoginCard = true;
                              _dismissalThresholdCrossed = false;
                            });
                            _loginCardController.forward();
                          }
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
          if (_showLoginCard && _controllersInitialized)
            AnimatedBuilder(
              animation: _loginCardController,
              builder: (context, child) {
                return Positioned(
                  bottom: -300 + (_loginCardController.value * 300),
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (_loginCardController.value > 0.1) {
                        final newValue =
                            _loginCardController.value -
                            (details.delta.dy / 200);
                        final clampedValue = newValue.clamp(0.0, 1.0);
                        _loginCardController.value = clampedValue;

                        if (clampedValue < 0.7) {
                          _dismissalThresholdCrossed = true;
                        } else if (clampedValue > 0.8) {
                          _dismissalThresholdCrossed = false;
                        }
                      }
                    },
                    onVerticalDragEnd: (details) {
                      if (_dismissalThresholdCrossed &&
                          _loginCardController.value < 0.7) {
                        _loginCardController.reverse().then((_) {
                          if (mounted) {
                            setState(() {
                              _showLoginCard = false;
                              _dismissalThresholdCrossed = false;
                            });
                          }
                        });
                      } else {
                        _loginCardController.forward();
                        _dismissalThresholdCrossed = false;
                      }
                    },
                    child: Container(
                      height: 300,
                      decoration: const BoxDecoration(
                        color: Colors.white,
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
                          ..._buildScatteredImages(),
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
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Welcome text
                                const Text(
                                  'Welcome to PlayWaves',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'Wednesday',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to sync your music across devices',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                // Animated Google Login Button
                                _buildAnimatedGoogleLoginButton(),
                                const SizedBox(height: 11),
                                // Skip button
                                TextButton(
                                  onPressed: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                      'welcome_skipped',
                                      true,
                                    );
                                    if (!mounted) return;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const HomePage(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: Text(
                                    'Skip for now',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.7),
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

  Widget _buildAnimatedGoogleLoginButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _buttonAnimationController,
        _pulseController,
      ]),
      builder: (context, child) {
        return GestureDetector(
          onTapDown: _onButtonTapDown,
          onTapUp: _onButtonTapUp,
          onTapCancel: _onButtonTapCancel,
          child: Transform.scale(
            scale: _buttonScaleAnimation.value,
            child: Transform.rotate(
              angle: _buttonRotationAnimation.value,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [
                            _buttonColorAnimation.value ??
                                const Color(0xFF6366f1),
                            const Color(0xFF8b5cf6),
                          ]
                        : [const Color(0xFF6366f1), const Color(0xFF8b5cf6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF6366f1,
                      ).withOpacity(_pulseAnimation.value),
                      blurRadius: 15 + (_pulseAnimation.value * 10),
                      spreadRadius: 1 + (_pulseAnimation.value * 2),
                      offset: const Offset(0, 2),
                    ),
                    // Additional inner glow
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: -2,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: _isLoading
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ]
                        : [
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
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? _buildLoadingWidget()
                          : _buildButtonContent(),
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

  Widget _buildLoadingWidget() {
    return Row(
      key: const ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Signing in with Google...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonContent() {
    return const Row(
      key: ValueKey('content'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.login, size: 24, color: Colors.white),
        SizedBox(width: 12),
        Text(
          'Google Login',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Google Sign-In...');
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        print('Successfully signed in: ${user.email}');

        // Keep loading state while navigating for better UX
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        print('Google sign-in was canceled or failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sign-in was canceled'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error during Google sign-in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Always reset loading state, even if widget is disposed
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      } else {
        _isLoading = false;
      }
    }
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

    final positions = [
      const Offset(50, 40),
      const Offset(160, 30),
      const Offset(270, 50),
      const Offset(30, 120),
      const Offset(180, 110),
      const Offset(290, 130),
      const Offset(80, 200),
      const Offset(240, 190),
    ];

    return List.generate(positions.length, (index) {
      final random = Random(index + 100);
      final imageIndex = random.nextInt(images.length);
      final basePosition = positions[index];

      final left = basePosition.dx + (random.nextDouble() - 0.5) * 40;
      final top = basePosition.dy + (random.nextDouble() - 0.5) * 30;

      return Positioned(
        left: left.clamp(10, 280),
        top: top.clamp(20, 240),
        child: Transform.rotate(
          angle: random.nextDouble() * 0.8 - 0.4,
          child: Opacity(
            opacity: 0.15 + random.nextDouble() * 0.15,
            child: Image.asset(
              images[imageIndex],
              width: 45 + random.nextDouble() * 25,
              height: 45 + random.nextDouble() * 25,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedBackground(BuildContext context) {
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

    final bodyX = size.width / 2;
    final bodyY = size.height * 0.6;
    canvas.drawCircle(Offset(bodyX, bodyY), 1.5, paint);

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
