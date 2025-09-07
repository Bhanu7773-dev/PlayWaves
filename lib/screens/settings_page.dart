import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/player_state_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import 'preset_store.dart';
import '../services/custom_theme_provider.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onLogout;
  final void Function(int) onNavTap;
  final int selectedNavIndex;

  const SettingsPage({
    Key? key,
    required this.onLogout,
    required this.onNavTap,
    required this.selectedNavIndex,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  bool useSystemTheme = false;
  bool useDynamicColors = false;
  bool customColorsEnabled = false;
  bool pitchBlackEnabled = false;
  bool offlineMode = false;
  bool materialPresetEnabled = false; // Added for Material Preset toggle
  Color pickedPrimaryColor = const Color(0xFFff7d78);
  Color pickedSecondaryColor = const Color(0xFF16213e);

  final List<Color> defaultGradient = [Color(0xFF6366f1), Color(0xFF8b5cf6)];
  final Color defaultPrimaryColor = Color(0xFF6366f1);
  final Color defaultSecondaryColor = Color(0xFF16213e);

  Color get primaryColor {
    final provider = Provider.of<CustomThemeProvider>(context);
    if (materialPresetEnabled) {
      return provider.primaryColor; // Preset color from provider
    }
    if (customColorsEnabled) {
      return provider.primaryColor;
    }
    return defaultPrimaryColor;
  }

  Color get secondaryColor {
    final provider = Provider.of<CustomThemeProvider>(context);
    if (materialPresetEnabled) {
      return provider.secondaryColor; // Preset color from provider
    }
    if (customColorsEnabled) {
      return provider.secondaryColor;
    }
    return defaultSecondaryColor;
  }

  final List<String> audioQualities = [
    'Low (96 kbps)',
    'Medium (160 kbps)',
    'High (320 kbps)',
  ];
  final List<String> downloadQualities = [
    'Low (96 kbps)',
    'Medium (160 kbps)',
    'High (320 kbps)',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _meteorsController;

  int totalListeningMinutes = 1234;
  int songsPlayed = 567;
  String topArtist = "Arijit Singh";
  String topSong = "Tum Hi Ho";
  int totalDownloads = 89;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _meteorsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _animationController.forward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      useSystemTheme = prefs.getBool('useSystemTheme') ?? false;
      useDynamicColors = prefs.getBool('useDynamicColors') ?? false;
      customColorsEnabled = prefs.getBool('customColorsEnabled') ?? false;
      pitchBlackEnabled = prefs.getBool('pitchBlackEnabled') ?? false;
      offlineMode = prefs.getBool('offlineMode') ?? false;
      materialPresetEnabled =
          prefs.getBool('materialPresetEnabled') ?? false; // Added
      pickedPrimaryColor = Color(prefs.getInt('primaryColor') ?? 0xFFff7d78);
      pickedSecondaryColor = Color(
        prefs.getInt('secondaryColor') ?? 0xFF16213e,
      );
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('useSystemTheme', useSystemTheme);
    prefs.setBool('useDynamicColors', useDynamicColors);
    prefs.setBool('customColorsEnabled', customColorsEnabled);
    prefs.setBool('pitchBlackEnabled', pitchBlackEnabled);
    prefs.setBool('offlineMode', offlineMode);
    prefs.setBool('materialPresetEnabled', materialPresetEnabled); // Added
    prefs.setInt('primaryColor', pickedPrimaryColor.value);
    prefs.setInt('secondaryColor', pickedSecondaryColor.value);
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // FIX: Provider is always updated when toggles change
  void _handleThemeToggle(String key, bool value) {
    setState(() {
      if (key == 'dynamic') {
        useDynamicColors = value;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('useDynamicColors', value);
        });
        Provider.of<CustomThemeProvider>(
          context,
          listen: false,
        ).setUseDynamicColors(value);
        if (value) {
          customColorsEnabled = false;
          pitchBlackEnabled = false;
          context.read<PitchBlackThemeProvider>().setPitchBlack(false);
          Provider.of<CustomThemeProvider>(
            context,
            listen: false,
          ).setCustomColorsEnabled(false);
        }
      } else if (key == 'custom') {
        customColorsEnabled = value;
        if (value) {
          useDynamicColors = false;
          pitchBlackEnabled = false;
          context.read<PitchBlackThemeProvider>().setPitchBlack(false);
          Provider.of<CustomThemeProvider>(
            context,
            listen: false,
          ).setCustomColorsEnabled(true);
        } else {
          Provider.of<CustomThemeProvider>(
            context,
            listen: false,
          ).setCustomColorsEnabled(false);
        }
      } else if (key == 'pitchBlack') {
        pitchBlackEnabled = value;
        context.read<PitchBlackThemeProvider>().setPitchBlack(value);
        if (value) {
          useDynamicColors = false;
          customColorsEnabled = false;
          Provider.of<CustomThemeProvider>(
            context,
            listen: false,
          ).setCustomColorsEnabled(false);
        }
      } else if (key == 'materialPreset') {
        materialPresetEnabled = value;
        if (value) {
          useDynamicColors = false;
          customColorsEnabled = false;
          pitchBlackEnabled = false;
          context.read<PitchBlackThemeProvider>().setPitchBlack(false);
          Provider.of<CustomThemeProvider>(
            context,
            listen: false,
          ).setCustomColorsEnabled(false);
          Provider.of<CustomThemeProvider>(
            context,
            listen: false,
          ).setUseDynamicColors(false);
        }
      }
    });
    _saveSettings();
  }

  Future<Color?> showInlineColorPickerDialog(
    BuildContext context,
    Color initialColor,
    String label,
  ) async {
    Color selectedColor = initialColor;
    final List<Color> materialPresets = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];
    TextEditingController hexController = TextEditingController(
      text:
          '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );
    bool showCustomPicker = false;
    Color customColor = selectedColor;
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Pick $label Color',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: materialPresets
                            .map(
                              (color) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                    customColor = color;
                                    hexController.text =
                                        '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == color
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Text('Custom', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: hexController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '#RRGGBB',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                              ),
                              onChanged: (value) {
                                if (value.startsWith('#') &&
                                    value.length == 7) {
                                  try {
                                    final color = Color(
                                      int.parse(
                                        'FF${value.substring(1)}',
                                        radix: 16,
                                      ),
                                    );
                                    setState(() {
                                      selectedColor = color;
                                      customColor = color;
                                    });
                                  } catch (_) {}
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showCustomPicker = !showCustomPicker;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: customColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.colorize,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (showCustomPicker) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Custom Color',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: customColor,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'R',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.red),
                            ),
                            Expanded(
                              child: Slider(
                                value: customColor.red.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.red,
                                onChanged: (value) {
                                  setState(() {
                                    customColor = customColor.withRed(
                                      value.toInt(),
                                    );
                                    selectedColor = customColor;
                                    hexController.text =
                                        '#${customColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                                  });
                                },
                              ),
                            ),
                            Text(
                              customColor.red.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'G',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.green),
                            ),
                            Expanded(
                              child: Slider(
                                value: customColor.green.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.green,
                                onChanged: (value) {
                                  setState(() {
                                    customColor = customColor.withGreen(
                                      value.toInt(),
                                    );
                                    selectedColor = customColor;
                                    hexController.text =
                                        '#${customColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                                  });
                                },
                              ),
                            ),
                            Text(
                              customColor.green.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'B',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.blue),
                            ),
                            Expanded(
                              child: Slider(
                                value: customColor.blue.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.blue,
                                onChanged: (value) {
                                  setState(() {
                                    customColor = customColor.withBlue(
                                      value.toInt(),
                                    );
                                    selectedColor = customColor;
                                    hexController.text =
                                        '#${customColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                                  });
                                },
                              ),
                            ),
                            Text(
                              customColor.blue.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selectedColor),
                  child: const Text(
                    'Select',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPitchBlack =
        context.watch<PitchBlackThemeProvider>().isPitchBlack ||
        pitchBlackEnabled;
    final provider = Provider.of<CustomThemeProvider>(context);
    final useMaterialPreset = materialPresetEnabled;
    final useCustomColors = customColorsEnabled;
    final scheme = Theme.of(context).colorScheme;
    Color bgColor = (isPitchBlack || useMaterialPreset)
        ? Colors.black
        : useDynamicColors
        ? scheme.background
        : useCustomColors
        ? provider.secondaryColor
        : defaultSecondaryColor;
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(
            isPitchBlack: isPitchBlack,
            useDynamicColors: useDynamicColors,
            scheme: scheme,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(isPitchBlack),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildMusicStatsCard(isPitchBlack),
                            const SizedBox(height: 24),
                            _buildThemeSection(context, isPitchBlack),
                            const SizedBox(height: 20),
                            _buildAudioSection(isPitchBlack),
                            const SizedBox(height: 20),
                            _buildSystemSection(isPitchBlack),
                            const SizedBox(height: 24),
                            _buildDeveloperInfoCard(isPitchBlack),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground({
    required bool isPitchBlack,
    required bool useDynamicColors,
    required ColorScheme scheme,
  }) {
    // Accept new params for dynamic color
    final useMaterialPreset = materialPresetEnabled;
    final useDynamicColors = this.useDynamicColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: isPitchBlack || useMaterialPreset
            ? null
            : useDynamicColors
            ? RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [scheme.background, scheme.surface, Colors.black],
              )
            : null,
        color: isPitchBlack || useMaterialPreset
            ? Colors.black
            : useDynamicColors
            ? null
            : secondaryColor,
      ),
      child: Stack(
        children: List.generate(
          20,
          (index) => _buildMeteor(
            index,
            isPitchBlack: isPitchBlack || useMaterialPreset,
          ),
        ),
      ),
    );
  }

  Widget _buildMeteor(int index, {required bool isPitchBlack}) {
    final useMaterialPreset = materialPresetEnabled;
    final useDynamicColors = this.useDynamicColors;
    final useCustomColors = customColorsEnabled;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _meteorsController,
      builder: (context, child) {
        final double progress = _meteorsController.value;
        final double staggeredProgress = ((progress + (index * 0.1)) % 1.0)
            .clamp(0.0, 1.0);
        final meteorColor = (isPitchBlack || useMaterialPreset)
            ? Colors.white
            : useDynamicColors
            ? scheme.primary
            : useCustomColors
            ? primaryColor
            : primaryColor;
        return Positioned(
          top: (index * 60.0) % MediaQuery.of(context).size.height,
          left: (index * 90.0) % MediaQuery.of(context).size.width,
          child: Transform.translate(
            offset: Offset(
              staggeredProgress * 100 - 50,
              staggeredProgress * 100 - 50,
            ),
            child: Opacity(
              opacity: (isPitchBlack || useMaterialPreset)
                  ? (1.0 - staggeredProgress) * 0.6
                  : (1.0 - staggeredProgress) * 0.6,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: meteorColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isPitchBlack) {
    final provider = Provider.of<CustomThemeProvider>(context);
    final useMaterialPreset = materialPresetEnabled;
    final useCustomColors = customColorsEnabled;
    final scheme = Theme.of(context).colorScheme;
    Color headerColor = useCustomColors
        ? provider.primaryColor
        : useMaterialPreset
        ? provider.primaryColor
        : useDynamicColors
        ? scheme.primary
        : Color(0xFF6366f1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize your experience',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: headerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: headerColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient:
                  (!useCustomColors && !useMaterialPreset && !useDynamicColors)
                  ? const LinearGradient(
                      colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: (useCustomColors || useMaterialPreset)
                  ? headerColor
                  : useDynamicColors
                  ? scheme.primary
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: headerColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                widget.onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicStatsCard(bool isPitchBlack) {
    final provider = Provider.of<CustomThemeProvider>(context);
    final useMaterialPreset = materialPresetEnabled;
    final useCustomColors = customColorsEnabled;
    final scheme = Theme.of(context).colorScheme;
    Color statsColor = useCustomColors
        ? provider.primaryColor
        : useMaterialPreset
        ? scheme.primary
        : useDynamicColors
        ? scheme.primary
        : Color(0xFF6366f1);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: statsColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.05),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          Icons.bar_chart,
                          color: statsColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Your Music Journey",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatBox(
                  "Minutes",
                  "$totalListeningMinutes",
                  Icons.access_time,
                  (useMaterialPreset || useDynamicColors
                      ? scheme.primary
                      : null),
                ),
                _buildStatBox(
                  "Songs",
                  "$songsPlayed",
                  Icons.music_note,
                  (useMaterialPreset || useDynamicColors
                      ? scheme.primary
                      : null),
                ),
                _buildStatBox(
                  "Downloads",
                  "$totalDownloads",
                  Icons.download,
                  (useMaterialPreset || useDynamicColors
                      ? scheme.primary
                      : null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 330,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      (useMaterialPreset || useDynamicColors)
                          ? Icon(Icons.star, color: scheme.primary, size: 16)
                          : customColorsEnabled
                          ? Icon(Icons.star, color: primaryColor, size: 16)
                          : ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFF6366f1),
                                    Color(0xFF8b5cf6),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds);
                              },
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                      const SizedBox(width: 8),
                      const Text(
                        "Top Artist: ",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        topArtist,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      (useMaterialPreset || useDynamicColors)
                          ? Icon(
                              Icons.favorite,
                              color: scheme.primary,
                              size: 16,
                            )
                          : customColorsEnabled
                          ? Icon(Icons.favorite, color: primaryColor, size: 16)
                          : ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFF6366f1),
                                    Color(0xFF8b5cf6),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds);
                              },
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                      const SizedBox(width: 8),
                      const Text(
                        "Top Song: ",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Expanded(
                        child: Text(
                          topSong,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            iconColor != null
                ? Icon(icon, color: iconColor, size: 20)
                : customColorsEnabled
                ? Icon(icon, color: primaryColor, size: 20)
                : ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds);
                    },
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, bool isPitchBlack) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSection(
      title: "Themes & Appearance",
      icon: Icons.palette,
      iconColor: useDynamicColors ? scheme.primary : null,
      isPitchBlack: isPitchBlack,
      children: [
        _buildIOSToggle(
          title: "Material Preset",
          subtitle: "Use Material 3 color presets for your app's theme.",
          value: useDynamicColors,
          thumbIcon: Icons.palette,
          onChanged: (val) {
            if (useDynamicColors ||
                (!pitchBlackEnabled &&
                    !customColorsEnabled &&
                    !materialPresetEnabled)) {
              _handleThemeToggle('dynamic', val);
              // SnackBar removed
            }
          },
          isActive: useDynamicColors,
          otherActive:
              pitchBlackEnabled || customColorsEnabled || materialPresetEnabled,
          iconColor: useDynamicColors ? scheme.primary : null,
        ),
        if (useDynamicColors)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ColorPresetPage(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storefront, color: scheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Preset Store",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Browse and apply curated color palettes",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        _buildIOSToggle(
          title: "Pitch Black",
          subtitle: "Ultra dark mode for AMOLED screens",
          value: isPitchBlack,
          thumbIcon: Icons.brightness_2,
          onChanged: (val) {
            if (pitchBlackEnabled ||
                (!useDynamicColors &&
                    !customColorsEnabled &&
                    !materialPresetEnabled)) {
              _handleThemeToggle('pitchBlack', val);
              // SnackBar removed
            }
          },
          isActive: pitchBlackEnabled,
          otherActive:
              useDynamicColors || customColorsEnabled || materialPresetEnabled,
        ),
        _buildCustomColorsTile(context),
      ],
    );
  }

  Widget _buildIOSToggle({
    required String title,
    required String subtitle,
    required bool value,
    required IconData thumbIcon,
    required ValueChanged<bool> onChanged,
    required bool isActive,
    required bool otherActive,
    Color? iconColor,
  }) {
    final isDisabled = !isActive && otherActive;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: isDisabled ? null : () => onChanged(!value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: value
                        ? (useDynamicColors
                              ? LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : (!customColorsEnabled
                                    ? (iconColor != null
                                          ? LinearGradient(
                                              colors: [
                                                iconColor,
                                                iconColor.withOpacity(0.8),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF6366f1),
                                                Color(0xFF8b5cf6),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ))
                                    : LinearGradient(
                                        colors: [
                                          primaryColor,
                                          primaryColor.withOpacity(0.8),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )))
                        : null,
                    color: value ? null : Colors.grey.withOpacity(0.3),
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color:
                                  (customColorsEnabled
                                          ? primaryColor
                                          : iconColor ??
                                                const Color(0xFF6366f1))
                                      .withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              value ? thumbIcon : Icons.close,
                              key: ValueKey(value),
                              color: value
                                  ? (useDynamicColors
                                        ? Theme.of(context).colorScheme.primary
                                        : (customColorsEnabled
                                              ? primaryColor
                                              : iconColor ??
                                                    const Color(0xFF6366f1)))
                                  : Colors.grey[600],
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomColorsTile(BuildContext context) {
    final isDisabled =
        useDynamicColors || pitchBlackEnabled || materialPresetEnabled;
    return Column(
      children: [
        Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Provider.of<CustomThemeProvider>(context).customIcon,
                    color: customColorsEnabled
                        ? Provider.of<CustomThemeProvider>(context).primaryColor
                        : Colors.white54,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Custom Colors",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Personalize your app colors",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                            final newValue = !customColorsEnabled;
                            _handleThemeToggle('custom', newValue);
                            Provider.of<CustomThemeProvider>(
                              context,
                              listen: false,
                            ).setCustomColorsEnabled(newValue);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 60,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: customColorsEnabled
                            ? LinearGradient(
                                colors: [
                                  Provider.of<CustomThemeProvider>(
                                    context,
                                  ).primaryColor,
                                  Provider.of<CustomThemeProvider>(
                                    context,
                                  ).primaryColor.withOpacity(0.8),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: customColorsEnabled
                            ? null
                            : Colors.grey.withOpacity(0.3),
                        boxShadow: customColorsEnabled
                            ? [
                                BoxShadow(
                                  color: Provider.of<CustomThemeProvider>(
                                    context,
                                  ).primaryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: customColorsEnabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  customColorsEnabled
                                      ? Icons.color_lens
                                      : Icons.close,
                                  key: ValueKey(customColorsEnabled),
                                  color: customColorsEnabled
                                      ? Provider.of<CustomThemeProvider>(
                                          context,
                                        ).primaryColor
                                      : Colors.grey[600],
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (materialPresetEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ColorPresetPage(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storefront, color: Colors.white70),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Preset Store",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Browse and apply curated color palettes",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (customColorsEnabled && !isDisabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Primary Color",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          Color? selected = await showInlineColorPickerDialog(
                            context,
                            Provider.of<CustomThemeProvider>(
                              context,
                              listen: false,
                            ).primaryColor,
                            "Primary",
                          );
                          if (selected != null) {
                            setState(() {
                              pickedPrimaryColor = selected;
                            });
                            Provider.of<CustomThemeProvider>(
                              context,
                              listen: false,
                            ).setPrimaryColor(selected);
                          }
                        },
                        child: Container(
                          height: 36,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Provider.of<CustomThemeProvider>(
                              context,
                            ).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Secondary Color",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          Color? selected = await showInlineColorPickerDialog(
                            context,
                            Provider.of<CustomThemeProvider>(
                              context,
                              listen: false,
                            ).secondaryColor,
                            "Secondary",
                          );
                          if (selected != null) {
                            setState(() {
                              pickedSecondaryColor = selected;
                            });
                            Provider.of<CustomThemeProvider>(
                              context,
                              listen: false,
                            ).setSecondaryColor(selected);
                          }
                        },
                        child: Container(
                          height: 36,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Provider.of<CustomThemeProvider>(
                              context,
                            ).secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAudioSection(bool isPitchBlack) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, child) {
        return _buildSection(
          title: "Audio & Playback",
          icon: Icons.audiotrack,
          iconColor: useDynamicColors ? scheme.primary : null,
          isPitchBlack: isPitchBlack,
          children: [
            _buildQualitySelector(
              icon: Icons.high_quality,
              title: "Audio Quality",
              subtitle: "Quality for streaming music",
              currentValue: playerState.audioQuality ?? 'High (320 kbps)',
              options: audioQualities,
              onChanged: (value) {
                playerState.setAudioQuality(value);
              },
            ),
            _buildQualitySelector(
              icon: Icons.download,
              title: "Download Quality",
              subtitle: "Quality for downloaded music",
              currentValue: playerState.downloadQuality ?? 'High (320 kbps)',
              options: downloadQualities,
              onChanged: (value) {
                playerState.setDownloadQuality(value);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQualitySelector({
    required IconData icon,
    required String title,
    required String subtitle,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    // Removed unused variable isPitchBlack
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.2,
            ),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: useDynamicColors
                  ? scheme.primary
                  : (title == "Language" || title == "Notifications")
                  ? Colors.grey[400]
                  : Colors.white,
            ),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: useDynamicColors
                        ? LinearGradient(
                            colors: [
                              scheme.primary,
                              scheme.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : !customColorsEnabled
                        ? const LinearGradient(
                            colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: customColorsEnabled ? primaryColor : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            onTap: () =>
                _showQualityDialog(title, currentValue, options, onChanged),
          ),
        ),
      ),
    );
  }

  void _showQualityDialog(
    String title,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    // Removed unused variable isPitchBlack
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: useDynamicColors
                                      ? scheme.primary
                                      : customColorsEnabled
                                      ? primaryColor
                                      : Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  title.contains('Audio')
                                      ? Icons.high_quality
                                      : Icons.download,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Select $title',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: options.map((option) {
                              final isSelected = option == selectedValue;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: useDynamicColors
                                      ? (isSelected
                                            ? scheme.primary.withOpacity(0.12)
                                            : scheme.primary.withOpacity(0.05))
                                      : isSelected
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? (useDynamicColors
                                              ? scheme.primary
                                              : customColorsEnabled
                                              ? primaryColor
                                              : const Color(0xFF8b5cf6))
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? (useDynamicColors
                                                ? scheme.primary
                                                : customColorsEnabled
                                                ? primaryColor
                                                : const Color(0xFF8b5cf6))
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  leading: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: useDynamicColors
                                              ? scheme.primary
                                              : customColorsEnabled
                                              ? primaryColor
                                              : const Color(0xFF8b5cf6),
                                        )
                                      : const Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.white54,
                                        ),
                                  onTap: () {
                                    setState(() {
                                      selectedValue = option;
                                    });
                                    onChanged(option);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            bottom: 16.0,
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white54),
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
        );
      },
    );
  }

  Widget _buildSystemSection(bool isPitchBlack) {
    return _buildSection(
      title: "System & Preferences",
      icon: Icons.settings,
      isPitchBlack: isPitchBlack,
      children: [
        _buildIOSToggle(
          title: "Offline Mode",
          subtitle: "Only show/play downloaded and local songs",
          value: offlineMode,
          thumbIcon: Icons.cloud_off,
          onChanged: (val) {
            setState(() {
              offlineMode = val;
            });
            _saveSettings();
          },
          isActive: offlineMode,
          otherActive: false,
        ),
        _buildSettingsTile(
          icon: Icons.language,
          title: "Language",
          subtitle: "English",
          onTap: () {
            // SnackBar removed
          },
        ),
        _buildSettingsTile(
          icon: Icons.notifications,
          title: "Notifications",
          subtitle: "Manage notification settings",
          onTap: () {
            // SnackBar removed
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isPitchBlack = false,
    Color? iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: useDynamicColors
                            ? Theme.of(context).colorScheme.primary
                            : (iconColor ??
                                  (customColorsEnabled
                                      ? primaryColor
                                      : Colors.white)),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Removed unused variable isPitchBlack
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: (title == "Language" || title == "Notifications")
            ? Icon(
                icon,
                color: useDynamicColors
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400],
              )
            : Container(
                decoration: BoxDecoration(
                  color: customColorsEnabled ? primaryColor : null,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: Colors.white),
              ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDeveloperInfoCard(bool isPitchBlack) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: useDynamicColors
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/image/dev_avatar.png'),
                  radius: 30,
                  backgroundColor: useDynamicColors
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🌑 I am DARK 🌑',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'BCA Student & Aspiring Developer',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  "Hope you're enjoying my PlayWaves app!",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: useDynamicColors
                        ? Theme.of(context).colorScheme.primary
                        : Color(0xFF6366F1),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Special thanks to our amazing collaborators:\nineffable & darkx dev',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '"Code, Create, Conquer!"',
                style: TextStyle(
                  fontSize: 13,
                  color: useDynamicColors
                      ? Theme.of(context).colorScheme.primary
                      : Colors.amberAccent,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGlassSocialButton(
                    FontAwesomeIcons.github,
                    Colors.white,
                    () => _launchURL("https://github.com/Bhanu7773-dev"),
                  ),
                  const SizedBox(width: 12),
                  _buildGlassSocialButton(
                    FontAwesomeIcons.telegram,
                    Color(0xFF29A7DF),
                    () => _launchURL("https://t.me/darkdevil7773"),
                  ),
                  const SizedBox(width: 12),
                  _buildGlassSocialButton(
                    FontAwesomeIcons.instagram,
                    Colors.pinkAccent,
                    () => _launchURL(
                      "https://www.instagram.com/bhanu.pratap__7773?igsh=MWZoM2w5NTZqeHc2NQ==",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  'App Version: 1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: useDynamicColors
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white60,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSocialButton(
    IconData icon,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor, size: 20),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _meteorsController.dispose();
    super.dispose();
  }
}
