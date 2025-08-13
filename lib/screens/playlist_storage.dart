import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/pitch_black_theme_provider.dart'; // <-- Add this import
import '../services/custom_theme_provider.dart';
import '../widgets/animated_navbar.dart'; // <-- Make sure this path is correct!

class LibraryScreen extends StatefulWidget {
  final Function(int)? onNavTap;
  final int selectedNavIndex;

  const LibraryScreen({Key? key, this.onNavTap, this.selectedNavIndex = 2})
    : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _floatController;
  late AnimationController _rippleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    try {
      _initializeAnimations();
      _startAnimations();
    } catch (e) {
      // Handle animation initialization errors gracefully
      debugPrint('Animation initialization error: $e');
    }
  }

  void _initializeAnimations() {
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(
        seconds: 8,
      ), // Slower animation to reduce CPU usage
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _masterController, curve: Curves.easeOut),
        );
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  void _startAnimations() {
    _masterController.forward();
    _floatController.repeat(reverse: true);
    _rippleController.repeat();
  }

  @override
  void dispose() {
    _masterController.stop();
    _floatController.stop();
    _rippleController.stop();
    _masterController.dispose();
    _floatController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else {
      if (widget.onNavTap != null) {
        widget.onNavTap!(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPitchBlack = context
        .watch<PitchBlackThemeProvider>()
        .isPitchBlack; // <-- Provider
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    final secondaryColor = customTheme.secondaryColor;
    final libraryItems = [
      LibraryItemData(
        title: "Favorites",
        subtitle: "247 songs",
        iconData: Icons.favorite,
        gradient: customColorsEnabled
            ? [primaryColor, primaryColor.withOpacity(0.7)]
            : const [Color(0xFFff7d78), Color(0xFFf54ea2)],
        isActive: true,
        onTap: () {},
      ),
      LibraryItemData(
        title: "My Playlists",
        subtitle: "18 playlists",
        iconData: Icons.queue_music,
        gradient: customColorsEnabled
            ? [primaryColor, primaryColor]
            : const [Color(0xFF667eea), Color(0xFF764ba2)],
        onTap: () {},
      ),
      LibraryItemData(
        title: "Recently Played",
        subtitle: "89 tracks",
        iconData: Icons.history,
        gradient: customColorsEnabled
            ? [primaryColor, primaryColor]
            : const [Color(0xFF9c27b0), Color(0xFFe91e63)],
        onTap: () {},
      ),
      LibraryItemData(
        title: "Downloaded",
        subtitle: "32 songs",
        iconData: Icons.download_done,
        gradient: customColorsEnabled
            ? [primaryColor, primaryColor]
            : const [Color(0xFF4facfe), Color(0xFF00f2fe)],
        onTap: () {},
      ),
      LibraryItemData(
        title: "Albums",
        subtitle: "12 albums",
        iconData: Icons.album,
        gradient: customColorsEnabled
            ? [primaryColor.withOpacity(0.9), primaryColor.withOpacity(0.6)]
            : const [Color(0xFF43e97b), Color(0xFF38f9d7)],
        onTap: () {},
      ),
      LibraryItemData(
        title: "Artists",
        subtitle: "34 artists",
        iconData: Icons.person,
        gradient: customColorsEnabled
            ? [primaryColor, primaryColor]
            : const [Color(0xFFfa709a), Color(0xFFfee140)],
        onTap: () {},
      ),
    ];

    return Scaffold(
      backgroundColor: isPitchBlack
          ? Colors.black
          : customColorsEnabled
          ? secondaryColor
          : Colors.black, // <-- Provider
      body: Stack(
        children: [
          _buildStardustBackground(
            isPitchBlack: isPitchBlack,
          ), // <-- Pass theme
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildLibraryItem(libraryItems[index], index),
                          childCount: libraryItems.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedNavBar(
              selectedIndex: widget.selectedNavIndex,
              onNavTap: _onNavTap,
              navIcons: const [
                Icons.home,
                Icons.search,
                Icons.playlist_play,
                Icons.person_outline,
              ],
              navLabels: const ['Home', 'Search', 'Playlist', 'Profile'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStardustBackground({required bool isPitchBlack}) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;
    final secondaryColor = customTheme.secondaryColor;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: isPitchBlack
                ? null
                : customColorsEnabled
                ? RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      secondaryColor,
                      secondaryColor.withOpacity(0.8),
                      Colors.black,
                    ],
                  )
                : const RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      Color(0xFF1a1a2e),
                      Color(0xFF16213e),
                      Colors.black,
                    ],
                  ),
            color: isPitchBlack ? Colors.black : null,
          ),
          child: Stack(
            children: [
              // Generate small floating meteors like settings page
              ...List.generate(12, (index) {
                final Color meteorColor = customColorsEnabled
                    ? primaryColor
                    : const Color(0xFFff7d78);

                return _buildFloatingMeteor(index, meteorColor, isPitchBlack);
              }),

              // Add background stars
              ...List.generate(20, (index) {
                final double offsetX = (index * 45.7) % 350;
                final double offsetY = (index * 78.2) % 600;

                return _buildBackgroundStar(offsetX, offsetY, index);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingMeteor(int index, Color meteorColor, bool isPitchBlack) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        final double progress = _floatAnimation.value;
        final double staggeredProgress = ((progress + (index * 0.08)) % 1.0)
            .clamp(0.0, 1.0);

        // Use screen size to position meteors properly
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Positioned(
          top: (index * 70.0) % screenHeight,
          left: (index * 110.0) % screenWidth,
          child: Transform.translate(
            offset: Offset(
              staggeredProgress * 120 - 60,
              staggeredProgress * 120 - 60,
            ),
            child: Opacity(
              opacity: isPitchBlack ? 0 : (1.0 - staggeredProgress) * 0.7,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: meteorColor,
                  boxShadow: [
                    BoxShadow(
                      color: meteorColor.withOpacity(0.5),
                      blurRadius: 6,
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

  Widget _buildBackgroundStar(double offsetX, double offsetY, int index) {
    // Create gentle twinkling effect
    final twinkle =
        0.3 + math.sin(_floatAnimation.value * 2 * math.pi + index * 0.8) * 0.4;
    final clampedTwinkle = twinkle.clamp(0.1, 0.7);

    return Positioned(
      left: offsetX,
      top: offsetY,
      child: Container(
        width: 2,
        height: 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(clampedTwinkle),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(
                (clampedTwinkle * 0.3).clamp(0.0, 1.0),
              ),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Library',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          customColorsEnabled
              ? Text(
                  'Music Collection',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                )
              : ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Music Collection',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              children: [
                const SizedBox(width: 20),
                customColorsEnabled
                    ? Icon(Icons.search_rounded, color: primaryColor, size: 24)
                    : ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Search your music...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
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

  Widget _buildLibraryItem(LibraryItemData item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(
            opacity: value,
            child: MinimalLibraryCard(item: item, index: index),
          ),
        );
      },
    );
  }
}

class LibraryItemData {
  final String title;
  final String subtitle;
  final IconData iconData;
  final List<Color> gradient;
  final bool isActive;
  final VoidCallback onTap;

  LibraryItemData({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.gradient,
    this.isActive = false,
    required this.onTap,
  });
}

class MinimalLibraryCard extends StatefulWidget {
  final LibraryItemData item;
  final int index;

  const MinimalLibraryCard({required this.item, required this.index, Key? key})
    : super(key: key);

  @override
  State<MinimalLibraryCard> createState() => _MinimalLibraryCardState();
}

class _MinimalLibraryCardState extends State<MinimalLibraryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.item.onTap,
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(
                      0.08 + _glowAnimation.value * 0.04,
                    ),
                    Colors.white.withOpacity(
                      0.04 + _glowAnimation.value * 0.02,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: widget.item.isActive
                      ? widget.item.gradient.first.withOpacity(0.3)
                      : Colors.white.withOpacity(
                          0.12 + _glowAnimation.value * 0.08,
                        ),
                  width: widget.item.isActive ? 1.5 : 1,
                ),
                boxShadow: [
                  if (widget.item.isActive)
                    BoxShadow(
                      color: widget.item.gradient.first.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.1 + _glowAnimation.value * 0.1,
                    ),
                    blurRadius: 15 + _glowAnimation.value * 10,
                    offset: const Offset(0, 5),
                  ),
                ],
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
                            colors: widget.item.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.item.gradient.first.withOpacity(
                                0.3,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.item.iconData,
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
                              widget.item.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: widget.item.isActive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.item.isActive)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: widget.item.gradient,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      else
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.4),
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
