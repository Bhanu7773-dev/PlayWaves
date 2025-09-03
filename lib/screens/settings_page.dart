import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/player_state_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../widgets/color_theme.dialogue.dart';
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
  Color pickedPrimaryColor = const Color(0xFFff7d78);
  Color pickedSecondaryColor = const Color(0xFF16213e);

  final List<Color> defaultGradient = [Color(0xFF6366f1), Color(0xFF8b5cf6)];
  final Color defaultPrimaryColor = Color(0xFF6366f1);
  final Color defaultSecondaryColor = Color(0xFF16213e);

  Color get primaryColor =>
      customColorsEnabled ? pickedPrimaryColor : defaultPrimaryColor;
  Color get secondaryColor =>
      customColorsEnabled ? pickedSecondaryColor : defaultSecondaryColor;

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
      }
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isPitchBlack =
        context.watch<PitchBlackThemeProvider>().isPitchBlack ||
        pitchBlackEnabled;
    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : secondaryColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(isPitchBlack: isPitchBlack),
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

  Widget _buildAnimatedBackground({required bool isPitchBlack}) {
    return Container(
      color: isPitchBlack ? Colors.black : secondaryColor,
      child: Stack(
        children: List.generate(
          20,
          (index) => _buildMeteor(index, isPitchBlack: isPitchBlack),
        ),
      ),
    );
  }

  Widget _buildMeteor(int index, {required bool isPitchBlack}) {
    return AnimatedBuilder(
      animation: _meteorsController,
      builder: (context, child) {
        final double progress = _meteorsController.value;
        final double staggeredProgress = ((progress + (index * 0.1)) % 1.0)
            .clamp(0.0, 1.0);
        return Positioned(
          top: (index * 60.0) % MediaQuery.of(context).size.height,
          left: (index * 90.0) % MediaQuery.of(context).size.width,
          child: Transform.translate(
            offset: Offset(
              staggeredProgress * 100 - 50,
              staggeredProgress * 100 - 50,
            ),
            child: Opacity(
              opacity: isPitchBlack ? 0 : (1.0 - staggeredProgress) * 0.6,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: primaryColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isPitchBlack) {
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
                    color: customColorsEnabled
                        ? primaryColor
                        : Color(0xFF6366f1),
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8b5cf6).withOpacity(0.3),
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
              gradient: !customColorsEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: customColorsEnabled ? primaryColor : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      (customColorsEnabled ? primaryColor : Color(0xFF6366f1))
                          .withOpacity(0.3),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
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
                  child: customColorsEnabled
                      ? ClipRRect(
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
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        )
                      : ClipRRect(
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
                              child: ShaderMask(
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
                                child: Icon(
                                  Icons.bar_chart,
                                  color: Colors.white,
                                  size: 24,
                                ),
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
                ),
                _buildStatBox("Songs", "$songsPlayed", Icons.music_note),
                _buildStatBox("Downloads", "$totalDownloads", Icons.download),
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
                      customColorsEnabled
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
                      customColorsEnabled
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

  Widget _buildStatBox(String label, String value, IconData icon) {
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
            customColorsEnabled
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
    return _buildSection(
      title: "Themes & Appearance",
      icon: Icons.palette,
      isPitchBlack: isPitchBlack,
      children: [
        _buildIOSToggle(
          title: "Dynamic Colors",
          subtitle: "Matches system accent color (Android 12+)",
          value: useDynamicColors,
          thumbIcon: Icons.auto_awesome,
          onChanged: (val) {
            if (useDynamicColors ||
                (!pitchBlackEnabled && !customColorsEnabled)) {
              _handleThemeToggle('dynamic', val);
              // SnackBar removed
            }
          },
          isActive: useDynamicColors,
          otherActive: pitchBlackEnabled || customColorsEnabled,
        ),
        _buildIOSToggle(
          title: "Pitch Black",
          subtitle: "Ultra dark mode for AMOLED screens",
          value: isPitchBlack,
          thumbIcon: Icons.brightness_2,
          onChanged: (val) {
            if (pitchBlackEnabled ||
                (!useDynamicColors && !customColorsEnabled)) {
              _handleThemeToggle('pitchBlack', val);
              // SnackBar removed
            }
          },
          isActive: pitchBlackEnabled,
          otherActive: useDynamicColors || customColorsEnabled,
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
                        ? (!customColorsEnabled
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF6366f1),
                                    Color(0xFF8b5cf6),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ))
                        : null,
                    color: value ? null : Colors.grey.withOpacity(0.3),
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color:
                                  (customColorsEnabled
                                          ? primaryColor
                                          : const Color(0xFF6366f1))
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
                                  ? (customColorsEnabled
                                        ? primaryColor
                                        : const Color(0xFF6366f1))
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
    final isDisabled = useDynamicColors || pitchBlackEnabled;
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
              Icon(
                Icons.palette,
                color: customColorsEnabled
                    ? pickedPrimaryColor
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
                              pickedPrimaryColor,
                              pickedPrimaryColor.withOpacity(0.8),
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
                              color: pickedPrimaryColor.withOpacity(0.4),
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
                                  ? pickedPrimaryColor
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

  Widget _buildAudioSection(bool isPitchBlack) {
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, child) {
        return _buildSection(
          title: "Audio & Playback",
          icon: Icons.audiotrack,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: (title == "Language" || title == "Notifications")
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
                    gradient: !customColorsEnabled
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
                                  color: customColorsEnabled
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
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? (customColorsEnabled
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
                                          ? (customColorsEnabled
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
                                          color: customColorsEnabled
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
  }) {
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
                      child: customColorsEnabled
                          ? Icon(icon, color: primaryColor, size: 20)
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
                              child: Icon(icon, color: Colors.white, size: 20),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: (title == "Language" || title == "Notifications")
            ? Icon(icon, color: Colors.grey[400])
            : Container(
                decoration: BoxDecoration(
                  gradient: !customColorsEnabled
                      ? const LinearGradient(
                          colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: !customColorsEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: customColorsEnabled ? primaryColor : null,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/image/dev_avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: !customColorsEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: customColorsEnabled ? primaryColor : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "🌑 I am DARK 🌑",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "BCA Student & Aspiring Developer",
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Text(
                  "Hope you're enjoying my PlayWaves Music App!",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "Special thanks to our amazing collaborators:\nineffable & darkx dev",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "\"Code, Create, Conquer!\"",
            style: TextStyle(
              fontSize: 14,
              color: Colors.amberAccent,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                FontAwesomeIcons.github,
                Colors.white,
                "GitHub",
                () => _launchURL("https://github.com/Bhanu7773-dev"),
              ),
              _buildSocialButton(
                FontAwesomeIcons.telegram,
                const Color(0xFF29A7DF),
                "Telegram",
                () => _launchURL("https://t.me/darkdevil7773"),
              ),
              _buildSocialButton(
                FontAwesomeIcons.instagram,
                Colors.pinkAccent,
                "Instagram",
                () => _launchURL(
                  "https://www.instagram.com/bhanu.pratap__7773?igsh=MWZoM2w5NTZqeHc2NQ==",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Text(
                  "App Version: 1.0.0",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Contact: bhanucv9887@gmail.com",
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
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
