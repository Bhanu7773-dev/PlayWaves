import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _SettingsPageState extends State<SettingsPage> {
  bool useSystemTheme = true;
  bool useDynamicColors = false;
  bool offlineMode = false; // New offline mode toggle

  // Example music stats, replace these with real stats from your app
  int totalListeningMinutes = 1234;
  int songsPlayed = 567;
  String topArtist = "Arijit Singh";
  String topSong = "Tum Hi Ho";

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not open $url")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: widget.onLogout,
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Music Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 24.0,
              ),
              child: _buildMusicStatsCard(),
            ),
            // Settings options
            Expanded(
              child: ListView(
                children: [
                  _buildSectionTitle("Themes & Appearance"),
                  _buildSwitchTile(
                    title: "Use system theme",
                    subtitle: "Automatically adapts to system light/dark mode",
                    value: useSystemTheme,
                    onChanged: (val) {
                      setState(() {
                        useSystemTheme = val;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: "Use dynamic colors",
                    subtitle: "Matches system accent color (Android 12+)",
                    value: useDynamicColors,
                    onChanged: (val) {
                      setState(() {
                        useDynamicColors = val;
                      });
                    },
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildSectionTitle("System"),
                  _buildSwitchTile(
                    title: "Offline Mode",
                    subtitle: "Only show/play downloaded and local songs",
                    value: offlineMode,
                    onChanged: (val) {
                      setState(() {
                        offlineMode = val;
                        // TODO: Implement offline mode logic in your app
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.white),
                    title: const Text(
                      "Language",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "English",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      // Show language picker
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                    title: const Text(
                      "Notifications",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "Manage notification settings",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      // Show notification settings
                    },
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  // Developer Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal: 16.0,
                    ),
                    child: _buildDeveloperInfoCard(),
                  ),
                ],
              ),
            ),
            // Bottom navigation bar (like library/profile pages)
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Music Stats",
            style: TextStyle(
              color: Color(0xFFff7d78),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox("Minutes", "$totalListeningMinutes"),
              _buildStatBox("Songs", "$songsPlayed"),
              _buildStatBox("Top Artist", topArtist),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Top Song: $topSong",
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFff7d78),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFff7d78),
      inactiveThumbColor: Colors.white24,
    );
  }

  Widget _buildDeveloperInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            backgroundImage: const AssetImage('assets/image/dev_avatar.png'),
            radius: 28,
          ),
          const SizedBox(height: 8),
          const Text(
            "🌑 I am DARK 🌑",
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            "BCA Student & Aspiring Developer",
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Hope you're enjoying my PlayWaves Music App!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF6366F1),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Special thanks to our amazing collaborators:\nineffable & darkx dev",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            "\"Code, Create, Conquer!\"",
            style: TextStyle(
              fontSize: 13,
              color: Colors.amberAccent,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.github, color: Colors.white),
                tooltip: "GitHub",
                onPressed: () => _launchURL("https://github.com/Bhanu7773-dev"),
              ),
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.telegram,
                  color: Color(0xFF29A7DF),
                ),
                tooltip: "Telegram",
                onPressed: () => _launchURL("https://t.me/darkdevil7773"),
              ),
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.instagram,
                  color: Colors.pinkAccent,
                ),
                tooltip: "Instagram",
                onPressed: () => _launchURL(
                  "https://www.instagram.com/bhanu.pratap__7773?igsh=MWZoM2w5NTZqeHc2NQ==",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "App Version: 1.0.0",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Contact: bhanucv9887@gmail.com",
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 62,
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navBarButton(icon: Icons.home, label: "Home", index: 0),
          _navBarButton(icon: Icons.search, label: "Search", index: 1),
          _navBarButton(icon: Icons.playlist_play, label: "Library", index: 2),
          _navBarButton(icon: Icons.person, label: "Profile", index: 3),
        ],
      ),
    );
  }

  Widget _navBarButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = widget.selectedNavIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => widget.onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFff7d78) : Colors.white54,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFff7d78) : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
