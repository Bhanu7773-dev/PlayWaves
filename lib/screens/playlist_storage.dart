import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';
import 'liked_songs_screen.dart';
import 'my_playlist_screen.dart';
import 'downloaded_songs_screen.dart';
import 'recently_played_screen.dart';
import '../services/player_state_provider.dart';
import '../logic/playlist_storage_logic.dart';

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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    PlaylistStorageLogic.openRecentlyPlayedBox();
    _masterController = PlaylistStorageLogic.createMasterController(this);
    _floatController = PlaylistStorageLogic.createFloatController(this);
    _fadeAnimation = PlaylistStorageLogic.createFadeAnimation(
      _masterController,
    );
    _slideAnimation = PlaylistStorageLogic.createSlideAnimation(
      _masterController,
    );
    _floatAnimation = PlaylistStorageLogic.createFloatAnimation(
      _floatController,
    );
    _masterController.forward();
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _masterController.stop();
    _floatController.stop();
    _masterController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final useDynamicColors = customTheme.useDynamicColors;
    final scheme = Theme.of(context).colorScheme;

    final primaryColor = customColorsEnabled
        ? customTheme.primaryColor
        : (useDynamicColors ? scheme.primary : scheme.primary);
    final secondaryColor = useDynamicColors
        ? scheme.secondary
        : customColorsEnabled
        ? customTheme.secondaryColor
        : scheme.secondary;
    final backgroundColor = isPitchBlack
        ? Colors.black
        : useDynamicColors
        ? scheme.background
        : customColorsEnabled
        ? secondaryColor
        : const Color(0xFF16213e);

    final accentGradient = useDynamicColors
        ? [scheme.primary, scheme.secondary]
        : customColorsEnabled
        ? [primaryColor, secondaryColor]
        : const [Color(0xFF6366f1), Color(0xFF8b5cf6)];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            _buildStardustBackground(
              isPitchBlack: isPitchBlack,
              scheme: scheme,
              accentGradient: accentGradient,
              useDynamicColors: useDynamicColors,
              customColorsEnabled: customColorsEnabled,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHeader(
                          scheme,
                          useDynamicColors,
                          customColorsEnabled,
                          primaryColor,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
                        sliver: Consumer<PlayerStateProvider>(
                          builder: (context, playerState, _) {
                            return FutureBuilder<int>(
                              future:
                                  PlaylistStorageLogic.getDownloadedSongsCount(),
                              builder: (context, snapshot) {
                                final likedSongsCount =
                                    PlaylistStorageLogic.getLikedSongsCount();
                                final playlistSongsCount =
                                    PlaylistStorageLogic.getPlaylistSongsCount();
                                final recentlyPlayedCount =
                                    playerState.recentlyPlayed.length;
                                final downloadedSongsCount = snapshot.data ?? 0;

                                final libraryItems = [
                                  LibraryItemData(
                                    title: "Favorites",
                                    subtitle:
                                        "$likedSongsCount ${likedSongsCount == 1 ? 'song' : 'songs'}",
                                    iconData: Icons.favorite,
                                    gradient: accentGradient,
                                    isActive: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LikedSongsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  LibraryItemData(
                                    title: "My Playlists",
                                    subtitle:
                                        "$playlistSongsCount ${playlistSongsCount == 1 ? 'song' : 'songs'}",
                                    iconData: Icons.queue_music,
                                    gradient: accentGradient,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MyPlaylistScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  LibraryItemData(
                                    title: "Recently Played",
                                    subtitle:
                                        "$recentlyPlayedCount ${recentlyPlayedCount == 1 ? 'track' : 'tracks'}",
                                    iconData: Icons.history,
                                    gradient: accentGradient,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RecentlyPlayedScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  LibraryItemData(
                                    title: "Downloaded",
                                    subtitle:
                                        "$downloadedSongsCount ${downloadedSongsCount == 1 ? 'song' : 'songs'}",
                                    iconData: Icons.download_done,
                                    gradient: accentGradient,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const DownloadedSongsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ];

                                return SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildLibraryItem(
                                      libraryItems[index],
                                      index,
                                      scheme,
                                      customColorsEnabled,
                                      primaryColor,
                                      secondaryColor,
                                      useDynamicColors,
                                      accentGradient,
                                    ),
                                    childCount: libraryItems.length,
                                  ),
                                );
                              },
                            );
                          },
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
    );
  }

  Widget _buildStardustBackground({
    required bool isPitchBlack,
    required ColorScheme scheme,
    required List<Color> accentGradient,
    required bool useDynamicColors,
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: isPitchBlack
                ? null
                : useDynamicColors
                ? RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [scheme.background, scheme.surface, Colors.black],
                  )
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
              ...List.generate(12, (index) {
                final Color meteorColor = useDynamicColors
                    ? scheme.primary
                    : customColorsEnabled
                    ? primaryColor
                    : accentGradient.first;
                return _buildFloatingMeteor(index, meteorColor, isPitchBlack);
              }),
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

  Widget _buildHeader(
    ColorScheme scheme,
    bool useDynamicColors,
    bool customColorsEnabled,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Library',
            style: TextStyle(
              color: useDynamicColors ? scheme.onBackground : Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Music Collection',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: customColorsEnabled
                  ? primaryColor
                  : (useDynamicColors
                        ? scheme.primary
                        : const Color(0xFF6366f1)),
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(
    LibraryItemData item,
    int index,
    ColorScheme scheme,
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
    bool useDynamicColors,
    List<Color> accentGradient,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(
            opacity: value,
            child: MinimalLibraryCard(
              item: item,
              index: index,
              scheme: scheme,
              customColorsEnabled: customColorsEnabled,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              useDynamicColors: useDynamicColors,
              accentGradient: accentGradient,
            ),
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
  final ColorScheme scheme;
  final bool customColorsEnabled;
  final Color primaryColor;
  final Color secondaryColor;
  final bool useDynamicColors;
  final List<Color> accentGradient;

  const MinimalLibraryCard({
    required this.item,
    required this.index,
    required this.scheme,
    required this.customColorsEnabled,
    required this.primaryColor,
    required this.secondaryColor,
    required this.useDynamicColors,
    required this.accentGradient,
    Key? key,
  }) : super(key: key);

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
    final scheme = widget.scheme;
    final customColorsEnabled = widget.customColorsEnabled;
    final useDynamicColors = widget.useDynamicColors;
    final primaryColor = widget.primaryColor;
    final secondaryColor = widget.secondaryColor;
    final accentGradient = widget.accentGradient;
    final bluePurpleGradient = const [Color(0xFF6366f1), Color(0xFF8b5cf6)];

    // Perfect logic for all icon containers:
    // 1. If customColorsEnabled, use primaryColor for icon bg and shadow.
    // 2. Else if useDynamicColors, use scheme.primary for icon bg and shadow.
    // 3. Else use bluePurpleGradient.

    Color? iconBgColor;
    Gradient? iconBgGradient;
    Color iconShadowColor;

    if (customColorsEnabled) {
      iconBgColor = primaryColor;
      iconBgGradient = null;
      iconShadowColor = primaryColor.withOpacity(0.3);
    } else if (useDynamicColors) {
      iconBgColor = scheme.primary;
      iconBgGradient = null;
      iconShadowColor = scheme.primary.withOpacity(0.3);
    } else {
      iconBgColor = null;
      iconBgGradient = LinearGradient(
        colors: bluePurpleGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      iconShadowColor = bluePurpleGradient.first.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: () {
        widget.item.onTap();
      },
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
                color: useDynamicColors
                    ? scheme.surface
                    : Colors.white.withOpacity(0.12),
                border: Border.all(
                  color: widget.item.isActive
                      ? (customColorsEnabled
                                ? primaryColor
                                : (useDynamicColors
                                      ? scheme.primary
                                      : bluePurpleGradient.first))
                            .withOpacity(0.3)
                      : scheme.outline.withOpacity(
                          0.12 + _glowAnimation.value * 0.08,
                        ),
                  width: widget.item.isActive ? 1.5 : 1,
                ),
                boxShadow: [
                  if (widget.item.isActive)
                    BoxShadow(
                      color:
                          (customColorsEnabled
                                  ? primaryColor
                                  : (useDynamicColors
                                        ? scheme.primary
                                        : bluePurpleGradient.first))
                              .withOpacity(0.2),
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
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: iconBgColor,
                        gradient: iconBgGradient,
                        boxShadow: [
                          BoxShadow(
                            color: iconShadowColor,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.item.iconData,
                        color:
                            customColorsEnabled && primaryColor == Colors.white
                            ? secondaryColor
                            : Colors.white,
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
                              color: scheme.onSurface,
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
                              color: scheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBgColor,
                        gradient: iconBgGradient,
                      ),
                      child: Icon(
                        widget.item.isActive
                            ? Icons.play_arrow
                            : Icons.arrow_forward_ios,
                        color:
                            customColorsEnabled && primaryColor == Colors.white
                            ? secondaryColor
                            : Colors.white,
                        size: widget.item.isActive ? 20 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
