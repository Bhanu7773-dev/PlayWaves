import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/player_state_provider.dart';

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
  bool useSystemTheme = true;
  bool useDynamicColors = false;
  bool offlineMode = false;

  // Remove local variables for audio/download quality,
  // use provider instead.
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

  // Example music stats
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildMusicStatsCard(),
                            const SizedBox(height: 24),
                            _buildThemeSection(),
                            const SizedBox(height: 20),
                            _buildAudioSection(), // Provider-based
                            const SizedBox(height: 20),
                            _buildSystemSection(),
                            const SizedBox(height: 24),
                            _buildDeveloperInfoCard(),
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

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Colors.black],
        ),
      ),
      child: Stack(children: List.generate(20, (index) => _buildMeteor(index))),
    );
  }

  Widget _buildMeteor(int index) {
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
              opacity: (1.0 - staggeredProgress) * 0.6,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFff7d78).withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(2)),
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
              gradient: const LinearGradient(
                colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFff7d78).withOpacity(0.3),
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

  Widget _buildMusicStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff7d78).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFff7d78).withOpacity(0.1),
              const Color(0xFF9c27b0).withOpacity(0.05),
            ],
          ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    ),
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
                      const Icon(
                        Icons.star,
                        color: Color(0xFFff7d78),
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
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFF9c27b0),
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
            Icon(icon, color: const Color(0xFFff7d78), size: 20),
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

  Widget _buildThemeSection() {
    return _buildSection(
      title: "Themes & Appearance",
      icon: Icons.palette,
      children: [
        _buildSwitchTile(
          title: "Use System Theme",
          subtitle: "Automatically adapts to system light/dark mode",
          value: useSystemTheme,
          onChanged: (val) {
            setState(() {
              useSystemTheme = val;
            });
            _showSnackBar("Theme setting updated", const Color(0xFFff7d78));
          },
        ),
        _buildSwitchTile(
          title: "Dynamic Colors",
          subtitle: "Matches system accent color (Android 12+)",
          value: useDynamicColors,
          onChanged: (val) {
            setState(() {
              useDynamicColors = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    // Use Provider for audio/download quality
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, child) {
        return _buildSection(
          title: "Audio & Playback",
          icon: Icons.audiotrack,
          children: [
            _buildQualitySelector(
              icon: Icons.high_quality,
              title: "Audio Quality",
              subtitle: "Quality for streaming music",
              currentValue: playerState.audioQuality ?? 'High (320 kbps)',
              options: audioQualities,
              onChanged: (value) {
                playerState.setAudioQuality(value);
                _showSnackBar(
                  "Audio quality updated to $value",
                  const Color(0xFFff7d78),
                );
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
                  const Color(0xFFff7d78),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFff7d78)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                  ),
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
                      ? const Color(0xFFff7d78).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFff7d78)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFff7d78)
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  leading: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFFff7d78))
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

  Widget _buildSystemSection() {
    return _buildSection(
      title: "System & Storage",
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
          icon: Icons.language,
          title: "Language",
          subtitle: "English",
          onTap: () {
            _showSnackBar("Language settings coming soon", Colors.blue);
          },
        ),
        _buildSettingsTile(
          icon: Icons.notifications,
          title: "Notifications",
          subtitle: "Manage notification settings",
          onTap: () {
            _showSnackBar("Notification settings coming soon", Colors.blue);
          },
        ),
        _buildSettingsTile(
          icon: Icons.storage,
          title: "Storage",
          subtitle: "Manage downloaded songs and cache",
          onTap: () {
            _showStorageDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    ),
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
        activeColor: const Color(0xFFff7d78),
        activeTrackColor: const Color(0xFFff7d78).withOpacity(0.3),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFff7d78)),
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

  Widget _buildDeveloperInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF9c27b0).withOpacity(0.1),
          ],
        ),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF9c27b0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF9c27b0)],
              ),
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
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onLogout();
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storage, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Storage Info',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStorageItem('Downloaded Songs', '2.3 GB'),
              _buildStorageItem('Cache', '456 MB'),
              _buildStorageItem('Playlists', '12 MB'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Color(0xFFff7d78), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total storage used: 2.77 GB',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnackBar("Cache cleared successfully", Colors.green);
                },
                child: const Text(
                  'Clear Cache',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorageItem(String label, String size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            size,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
