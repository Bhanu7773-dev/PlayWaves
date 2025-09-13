import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playwaves/models/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pitch_black_theme_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

// Enhanced cache for better performance
class _ColorSchemeCache {
  static final Map<String, ColorScheme> _lightCache = {};
  static final Map<String, ColorScheme> _darkCache = {};

  static ColorScheme getLightScheme(
    FlexScheme scheme,
    int blendLevel,
    bool swapColors,
  ) {
    final key = '${scheme.name}_$blendLevel\_$swapColors\_light';
    return _lightCache[key] ??= FlexThemeData.light(
      scheme: scheme,
      blendLevel: blendLevel,
      swapColors: swapColors,
    ).colorScheme;
  }

  static ColorScheme getDarkScheme(
    FlexScheme scheme,
    int blendLevel,
    bool swapColors,
  ) {
    final key = '${scheme.name}_$blendLevel\_$swapColors\_dark';
    return _darkCache[key] ??= FlexThemeData.dark(
      scheme: scheme,
      blendLevel: blendLevel,
      swapColors: swapColors,
    ).colorScheme;
  }

  // static void clearCache() {
  //   _lightCache.clear();
  //   _darkCache.clear();
  // }
}

class ColorPresetPage extends ConsumerStatefulWidget {
  const ColorPresetPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ColorPresetPage> createState() => _ColorPresetPageState();
}

class _ColorPresetPageState extends ConsumerState<ColorPresetPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _searchController;
  late AnimationController _fabController;

  late Animation<double> _heroAnimation;
  late Animation<double> _searchAnimation;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _fabSlideAnimation;

  String _searchQuery = '';
  bool _showSearchBar = false;
  String _selectedCategory = 'All';

  List<FlexScheme>? _cachedFilteredSchemes;
  String _lastSearchQuery = '';
  String _lastCategory = 'All';

  final List<String> _categories = [
    'All',
    'Material',
    'Blue',
    'Green',
    'Purple',
    'Red',
    'Orange',
    'Special',
  ];

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );

    _searchAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOutCubic,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );

    _fabSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_fabController);

    _startAnimations();
    _precachePopularSchemes();
  }

  void _startAnimations() async {
    _heroController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _fabController.forward();
  }

  void _precachePopularSchemes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schemes = FlexScheme.values;
      for (final scheme in schemes) {
        _ColorSchemeCache.getLightScheme(scheme, 0, false);
        _ColorSchemeCache.getDarkScheme(scheme, 0, false);
      }
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  List<FlexScheme> _getFilteredSchemes() {
    if (_lastSearchQuery == _searchQuery &&
        _lastCategory == _selectedCategory &&
        _cachedFilteredSchemes != null) {
      return _cachedFilteredSchemes!;
    }

    _lastSearchQuery = _searchQuery;
    _lastCategory = _selectedCategory;

    _cachedFilteredSchemes = FlexScheme.values.where((flexScheme) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = _formatSchemeName(flexScheme.name).toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'All') {
        final schemeName = flexScheme.name.toLowerCase();
        switch (_selectedCategory) {
          case 'Material':
            return schemeName.contains('material') || schemeName.contains('m3');
          case 'Blue':
            return schemeName.contains('blue') ||
                schemeName.contains('indigo') ||
                schemeName.contains('cyan');
          case 'Green':
            return schemeName.contains('green') || schemeName.contains('teal');
          case 'Purple':
            return schemeName.contains('purple') ||
                schemeName.contains('violet') ||
                schemeName.contains('deepPurple');
          case 'Red':
            return schemeName.contains('red') || schemeName.contains('pink');
          case 'Orange':
            return schemeName.contains('orange') ||
                schemeName.contains('amber') ||
                schemeName.contains('yellow');
          case 'Special':
            return schemeName.contains('brand') ||
                schemeName.contains('custom') ||
                schemeName.contains('vesuvius');
        }
      }

      return true;
    }).toList();

    return _cachedFilteredSchemes!;
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final scheme = Theme.of(context).colorScheme;
    final filteredSchemes = _getFilteredSchemes();

    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero App Bar
          _buildHeroAppBar(scheme, isPitchBlack),

          // Search & Filter Section
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchSection(scheme),
                _buildCategoryFilter(scheme),
                _buildStatsCard(scheme, filteredSchemes.length),
              ],
            ),
          ),

          // Grid Content
          _buildSliverGrid(filteredSchemes, themeSettings, scheme),
        ],
      ),

      // Floating Action Button for settings
      floatingActionButton: _buildFloatingButton(scheme),
    );
  }

  Widget _buildHeroAppBar(ColorScheme scheme, bool isPitchBlack) {
    return SliverAppBar(
      expandedHeight: 200,
      collapsedHeight: 80, // Increased collapsed height for header
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isPitchBlack ? Colors.black : scheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: AnimatedBuilder(
        animation: _heroAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _heroAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: scheme.onSurface,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          );
        },
      ),
      actions: [
        AnimatedBuilder(
          animation: _heroAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _heroAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _showSearchBar
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      key: ValueKey(_showSearchBar),
                      color: scheme.onSurface,
                      size: 20,
                    ),
                  ),
                  onPressed: _toggleSearch,
                ),
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        background: AnimatedBuilder(
          animation: _heroAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withOpacity(
                      0.1 * _heroAnimation.value,
                    ),
                    scheme.secondaryContainer.withOpacity(
                      0.05 * _heroAnimation.value,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: 50,
                    right: -50,
                    child: Opacity(
                      opacity: 0.1 * _heroAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: -30,
                    child: Opacity(
                      opacity: 0.05 * _heroAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        title: AnimatedBuilder(
          animation: _heroAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                32,
                20 * (1 - _heroAnimation.value),
              ), // Shift right by 32
              child: Opacity(
                opacity: _heroAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Color Presets',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Discover beautiful themes',
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
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

  Widget _buildSearchSection(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _searchAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search for your perfect theme...',
                hintStyle: TextStyle(
                  color: scheme.onSurface.withOpacity(0.5),
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: scheme.onSurface.withOpacity(0.6),
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(ColorScheme scheme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: scheme.surfaceContainerHigh,
              selectedColor: scheme.primary,
              checkmarkColor: scheme.onPrimary,
              side: BorderSide(
                color: isSelected
                    ? scheme.primary
                    : scheme.outline.withOpacity(0.2),
                width: 1,
              ),
              elevation: isSelected ? 4 : 0,
              shadowColor: scheme.primary.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme scheme, int count) {
    return AnimatedBuilder(
      animation: _heroAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _heroAnimation.value)),
          child: FadeTransition(
            opacity: _heroAnimation,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withOpacity(0.3),
                    scheme.tertiaryContainer.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: scheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Themes',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count beautiful color schemes ready to transform your app',
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildSliverGrid(
    List<FlexScheme> schemes,
    dynamic themeSettings,
    ColorScheme scheme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final flexScheme = schemes[index];
          return _ModernPresetCard(
            key: ValueKey(
              '${flexScheme.name}_${themeSettings.blendLevel}_${themeSettings.swapColors}',
            ),
            flexScheme: flexScheme,
            themeSettings: themeSettings,
            index: index,
            onTap: () => _handlePresetSelection(flexScheme),
          );
        }, childCount: schemes.length),
      ),
    );
  }

  Widget _buildFloatingButton(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _fabSlideAnimation,
          child: ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.extended(
              onPressed: () {
                // Add functionality for favorites or settings
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Favorites feature coming soon!'),
                      ],
                    ),
                    backgroundColor: scheme.primary.withOpacity(0.9),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
              icon: Icon(Icons.favorite_rounded, color: scheme.onPrimary),
              label: Text(
                'Favorites',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: scheme.primary,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchQuery = '';
        _cachedFilteredSchemes = null;
      }
    });

    if (_showSearchBar) {
      _searchController.forward();
    } else {
      _searchController.reverse();
    }
  }

  Future<void> _handlePresetSelection(FlexScheme flexScheme) async {
    final prefs = await SharedPreferences.getInstance();
    final useDynamicColors = prefs.getBool('useDynamicColors') ?? false;
    final scheme = Theme.of(context).colorScheme;

    if (!useDynamicColors) {
      _showAdvancedSnackBar(
        icon: Icons.lock_outline_rounded,
        title: 'Feature Locked',
        message: 'Enable "Dynamic Colors" in settings to apply presets',
        color: Colors.redAccent,
      );
      return;
    }

    // Update Riverpod provider and force rebuild
    ref
        .read(themeSettingsProvider.notifier)
        .updateSettings(
          (currentSettings) =>
              currentSettings.copyWith(flexScheme: flexScheme.name),
        );

    // Optionally, trigger a rebuild by updating a dummy value in SharedPreferences
    await prefs.setInt(
      'lastPresetApplied',
      DateTime.now().millisecondsSinceEpoch,
    );

    _showAdvancedSnackBar(
      icon: Icons.check_circle_outline_rounded,
      title: 'Theme Applied',
      message: 'Successfully applied "${_formatSchemeName(flexScheme.name)}"',
      color: scheme.primary,
    );
  }

  void _showAdvancedSnackBar({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  String _formatSchemeName(String name) {
    final formatted = name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim();

    return formatted
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          if (word.toLowerCase() == 'ios') return 'iOS';
          if (word.toLowerCase() == 'm3') return 'M3';
          if (word.toLowerCase() == 'hc') return 'HC';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

// New modern preset card design
class _ModernPresetCard extends StatefulWidget {
  final FlexScheme flexScheme;
  final dynamic themeSettings;
  final int index;
  final VoidCallback onTap;

  const _ModernPresetCard({
    super.key,
    required this.flexScheme,
    required this.themeSettings,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ModernPresetCard> createState() => _ModernPresetCardState();
}

class _ModernPresetCardState extends State<_ModernPresetCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _entryController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _entryAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 16.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    // Staggered entry with reduced delay
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = _ColorSchemeCache.getLightScheme(
      widget.flexScheme,
      widget.themeSettings.blendLevel,
      widget.themeSettings.swapColors,
    );

    final darkScheme = _ColorSchemeCache.getDarkScheme(
      widget.flexScheme,
      widget.themeSettings.blendLevel,
      widget.themeSettings.swapColors,
    );

    final currentScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final previewScheme = isDarkMode ? darkScheme : lightScheme;
    final isSelected =
        widget.themeSettings.flexScheme == widget.flexScheme.name;
    final name = _formatSchemeName(widget.flexScheme.name);

    return ScaleTransition(
      scale: _entryAnimation,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * (_isPressed ? 0.98 : 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? previewScheme.primary.withOpacity(0.4)
                            : currentScheme.shadow.withOpacity(0.15),
                        blurRadius: _elevationAnimation.value,
                        spreadRadius: isSelected ? 2 : 0,
                        offset: Offset(0, _elevationAnimation.value / 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: BoxDecoration(
                        color: currentScheme.surfaceContainerHigh,
                        border: Border.all(
                          color: isSelected
                              ? previewScheme.primary
                              : currentScheme.outline.withOpacity(0.1),
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          // Enhanced Color Preview
                          Expanded(
                            flex: 5,
                            child: Stack(
                              children: [
                                // Color Display with rounded corners
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(26),
                                    topRight: Radius.circular(26),
                                  ),
                                  child: Row(
                                    children: [
                                      // Main primary section
                                      Expanded(
                                        flex: 7,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                previewScheme.primary,
                                                previewScheme.primary
                                                    .withOpacity(0.8),
                                                previewScheme.primaryContainer,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Color accent strips
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      previewScheme.secondary,
                                                      previewScheme
                                                          .secondaryContainer,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      previewScheme.tertiary,
                                                      previewScheme
                                                          .tertiaryContainer,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                color: previewScheme
                                                    .surfaceContainerHighest,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Selection badge
                                if (isSelected)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: previewScheme.onPrimary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: previewScheme.primary
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: previewScheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                  ),

                                // Hover shimmer effect
                                if (_isHovered)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.white.withOpacity(0.1),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Info section with enhanced styling
                          Expanded(
                            flex: 4,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: currentScheme.surfaceContainerHigh,
                                border: isSelected
                                    ? Border(
                                        top: BorderSide(
                                          color: previewScheme.primary
                                              .withOpacity(0.3),
                                          width: 2,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? previewScheme.primary
                                          : currentScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),

                                  // Enhanced color indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _ColorIndicator(
                                        color: previewScheme.primary,
                                        size: 8,
                                        isSelected: isSelected,
                                      ),
                                      const SizedBox(width: 6),
                                      _ColorIndicator(
                                        color: previewScheme.secondary,
                                        size: 6,
                                        isSelected: isSelected,
                                      ),
                                      const SizedBox(width: 6),
                                      _ColorIndicator(
                                        color: previewScheme.tertiary,
                                        size: 5,
                                        isSelected: isSelected,
                                      ),
                                    ],
                                  ),

                                  if (isSelected) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 3,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            previewScheme.primary,
                                            previewScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
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
            },
          ),
        ),
      ),
    );
  }

  String _formatSchemeName(String name) {
    final formatted = name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim();

    return formatted
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          if (word.toLowerCase() == 'ios') return 'iOS';
          if (word.toLowerCase() == 'm3') return 'M3';
          if (word.toLowerCase() == 'hc') return 'HC';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class _ColorIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final bool isSelected;

  const _ColorIndicator({
    required this.color,
    required this.size,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
