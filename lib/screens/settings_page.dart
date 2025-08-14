import 'package:flutter/material.dart';
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

  final List<Color> defaultGradient = [Color(0xFFff7d78), Color(0xFF9c27b0)];
  final Color defaultPrimaryColor = Color(0xFFff7d78);
  final Color defaultSecondaryColor = Color(0xFF16213e);

  Color get primaryColor =>
      customColorsEnabled ? pickedPrimaryColor : defaultPrimaryColor;
  Color get secondaryColor =>
      customColorsEnabled ? pickedSecondaryColor : defaultSecondaryColor;

  List<Color> get iconGradient => customColorsEnabled
      ? [pickedPrimaryColor, pickedPrimaryColor]
      : defaultGradient;

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
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar("Could not open $url", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Mutually exclusive, but all can be off (default theme)
  void _handleThemeToggle(String key, bool value) {
    setState(() {
      if (key == 'system') {
        useSystemTheme = value;
        if (value) {
          useDynamicColors = false;
          customColorsEnabled = false;
          pitchBlackEnabled = false;
          context.read<PitchBlackThemeProvider>().setPitchBlack(false);
        }
      } else if (key == 'dynamic') {
        useDynamicColors = value;
        if (value) {
          useSystemTheme = false;
          customColorsEnabled = false;
          pitchBlackEnabled = false;
          context.read<PitchBlackThemeProvider>().setPitchBlack(false);
        }
      } else if (key == 'custom') {
        customColorsEnabled = value;
        if (value) {
          useSystemTheme = false;
          useDynamicColors = false;
          pitchBlackEnabled = false;
          context.read<PitchBlackThemeProvider>().setPitchBlack(false);
        }
      } else if (key == 'pitchBlack') {
        pitchBlackEnabled = value;
        context.read<PitchBlackThemeProvider>().setPitchBlack(value);
        if (value) {
          useSystemTheme = false;
          useDynamicColors = false;
          customColorsEnabled = false;
        }
      }
      // If all are false, show default gradient theme
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              gradient:
                  (!customColorsEnabled &&
                      !useSystemTheme &&
                      !useDynamicColors &&
                      !pitchBlackEnabled)
                  ? LinearGradient(
                      colors: defaultGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: customColorsEnabled ? primaryColor : null,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              gradient:
                  (!customColorsEnabled &&
                      !useSystemTheme &&
                      !useDynamicColors &&
                      !pitchBlackEnabled)
                  ? LinearGradient(
                      colors: defaultGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: customColorsEnabled ? primaryColor : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                _showLogoutDialog();
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
                    gradient:
                        (!customColorsEnabled &&
                            !useSystemTheme &&
                            !useDynamicColors &&
                            !pitchBlackEnabled)
                        ? LinearGradient(
                            colors: defaultGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: customColorsEnabled ? primaryColor : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Your Music Journey",
                  style: TextStyle(
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
                      Icon(
                        Icons.star,
                        color: customColorsEnabled
                            ? primaryColor
                            : defaultPrimaryColor,
                        size: 16,
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
                      Icon(
                        Icons.favorite,
                        color: customColorsEnabled
                            ? secondaryColor
                            : Color(0xFF9c27b0),
                        size: 16,
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
            Icon(
              icon,
              color: customColorsEnabled ? primaryColor : defaultPrimaryColor,
              size: 20,
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
        _buildSwitchTile(
          title: "Use System Theme",
          subtitle: "Automatically adapts to system light/dark mode",
          value: useSystemTheme,
          onChanged: (val) {
            _handleThemeToggle('system', val);
            if (val) _showSnackBar("System theme enabled", defaultPrimaryColor);
          },
        ),
        _buildSwitchTile(
          title: "Dynamic Colors",
          subtitle: "Matches system accent color (Android 12+)",
          value: useDynamicColors,
          onChanged: (val) {
            _handleThemeToggle('dynamic', val);
            if (val)
              _showSnackBar("Dynamic colors enabled", defaultPrimaryColor);
          },
        ),
        _buildSwitchTile(
          title: "Pitch Black",
          subtitle: "Ultra dark mode for AMOLED screens",
          value: isPitchBlack,
          onChanged: (val) {
            _handleThemeToggle('pitchBlack', val);
            if (val) _showSnackBar("Pitch Black enabled", Colors.black);
          },
        ),
        _buildCustomColorsTile(context),
      ],
    );
  }

  Widget _buildCustomColorsTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(
          Icons.palette,
          color: customColorsEnabled ? pickedPrimaryColor : Colors.white54,
        ),
        title: Text(
          "Custom Colors",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Personalize your app colors",
          style: TextStyle(color: Colors.white70),
        ),
        trailing: Switch(
          value: customColorsEnabled,
          onChanged: (val) {
            _handleThemeToggle('custom', val);
            // Update provider so all screens get notified
            Provider.of<CustomThemeProvider>(
              context,
              listen: false,
            ).setCustomColorsEnabled(val);
            if (val) {
              _showSnackBar("Custom colors enabled", pickedPrimaryColor);
            } else {
              _showSnackBar("Custom colors disabled", defaultPrimaryColor);
            }
          },
          activeColor: pickedPrimaryColor,
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => ColorThemeDialog(
              primaryColor: pickedPrimaryColor,
              secondaryColor: pickedSecondaryColor,
              onPrimaryColorChanged: (c) {
                setState(() {
                  pickedPrimaryColor = c;
                });
                // Debug print to check selected primary color
                print('[SettingsPage] Picked primaryColor: ' + c.toString());
                // Provide color data to CustomThemeProvider
                Provider.of<CustomThemeProvider>(
                  context,
                  listen: false,
                ).setPrimaryColor(c);
                _saveSettings();
              },
              onSecondaryColorChanged: (c) {
                setState(() {
                  pickedSecondaryColor = c;
                });
                // Debug print to check selected secondary color
                print('[SettingsPage] Picked secondaryColor: ' + c.toString());
                // Provide color data to CustomThemeProvider
                Provider.of<CustomThemeProvider>(
                  context,
                  listen: false,
                ).setSecondaryColor(c);
                _saveSettings();
              },
            ),
          );
        },
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
                _showSnackBar("Audio quality updated to $value", primaryColor);
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
                _showSnackBar(
                  "Download quality updated to $value",
                  primaryColor,
                );
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
    final isPitchBlack =
        context.watch<PitchBlackThemeProvider>().isPitchBlack ||
        pitchBlackEnabled;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            gradient:
                (!customColorsEnabled &&
                    !useSystemTheme &&
                    !useDynamicColors &&
                    !pitchBlackEnabled)
                ? LinearGradient(
                    colors: defaultGradient,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: customColorsEnabled ? primaryColor : defaultPrimaryColor,
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
    );
  }

  void _showQualityDialog(
    String title,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final isPitchBlack =
        context.watch<PitchBlackThemeProvider>().isPitchBlack ||
        pitchBlackEnabled;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient:
                      (!customColorsEnabled &&
                          !useSystemTheme &&
                          !useDynamicColors &&
                          !pitchBlackEnabled)
                      ? LinearGradient(
                          colors: defaultGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: customColorsEnabled ? primaryColor : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  title.contains('Audio') ? Icons.high_quality : Icons.download,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final isSelected = option == currentValue;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (customColorsEnabled
                            ? primaryColor.withOpacity(0.2)
                            : defaultPrimaryColor.withOpacity(0.2))
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (customColorsEnabled
                              ? primaryColor
                              : defaultPrimaryColor)
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
                                : defaultPrimaryColor)
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
                              : defaultPrimaryColor,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.white54,
                        ),
                  onTap: () {
                    onChanged(option);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemSection(bool isPitchBlack) {
    return _buildSection(
      title: "System & Storage",
      icon: Icons.settings,
      isPitchBlack: isPitchBlack,
      children: [
        _buildSwitchTile(
          title: "Offline Mode",
          subtitle: "Only show/play downloaded and local songs",
          value: offlineMode,
          onChanged: (val) {
            setState(() {
              offlineMode = val;
            });
            _saveSettings();
          },
        ),
        _buildSettingsTile(
          icon: Icons.language,
          title: "Language",
          subtitle: "English",
          onTap: () {
            _showSnackBar("Language settings coming soon", primaryColor);
          },
        ),
        _buildSettingsTile(
          icon: Icons.notifications,
          title: "Notifications",
          subtitle: "Manage notification settings",
          onTap: () {
            _showSnackBar("Notification settings coming soon", primaryColor);
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient:
                        (!customColorsEnabled &&
                            !useSystemTheme &&
                            !useDynamicColors &&
                            !pitchBlackEnabled)
                        ? LinearGradient(
                            colors: defaultGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: customColorsEnabled ? primaryColor : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: SwitchListTile.adaptive(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        value: value,
        onChanged: onChanged,
        activeColor: customColorsEnabled ? primaryColor : defaultPrimaryColor,
        activeTrackColor:
            (customColorsEnabled ? primaryColor : defaultPrimaryColor)
                .withOpacity(0.3),
        inactiveThumbColor: Colors.white24,
        inactiveTrackColor: Colors.white12,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isPitchBlack =
        context.watch<PitchBlackThemeProvider>().isPitchBlack ||
        pitchBlackEnabled;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            gradient:
                (!customColorsEnabled &&
                    !useSystemTheme &&
                    !useDynamicColors &&
                    !pitchBlackEnabled)
                ? LinearGradient(
                    colors: defaultGradient,
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
              gradient:
                  (!customColorsEnabled &&
                      !useSystemTheme &&
                      !useDynamicColors &&
                      !pitchBlackEnabled)
                  ? LinearGradient(
                      colors: defaultGradient,
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
              gradient:
                  (!customColorsEnabled &&
                      !useSystemTheme &&
                      !useDynamicColors &&
                      !pitchBlackEnabled)
                  ? LinearGradient(
                      colors: defaultGradient,
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildSection(
          title: "System",
          icon: Icons.settings,
          children: [
            _buildSwitchTile(
              title: "Offline Mode",
              subtitle: "Only show/play downloaded and local songs",
              value: offlineMode,
              onChanged: (val) {
                setState(() {
                  offlineMode = val;
                });
              },
            ),
            _buildSettingsTile(
              icon: Icons.notifications,
              title: "Notifications",
              subtitle: "Manage notification settings",
              onTap: () {
                _showSnackBar(
                  "Notification settings coming soon",
                  primaryColor,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _meteorsController.dispose();
    super.dispose();
  }
}
