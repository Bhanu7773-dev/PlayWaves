import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:install_plugin_v2_fork/install_plugin_v2_fork.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UpdateCheckerPage extends StatefulWidget {
  const UpdateCheckerPage({Key? key}) : super(key: key);

  @override
  State<UpdateCheckerPage> createState() => _UpdateCheckerPageState();
}

class _UpdateCheckerPageState extends State<UpdateCheckerPage>
    with TickerProviderStateMixin {
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _hasUpdate = false;
  double _downloadProgress = 0.0;
  String _currentVersion = '';
  String _downloadSpeed = '';

  Map<String, dynamic>? _latestRelease;

  late AnimationController _slideController;
  late AnimationController _breatheController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _getCurrentVersion();
    _checkForUpdates();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _breatheController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutExpo),
        );

    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/Bhanu7773-dev/PlayWaves-Releases/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final releaseData = jsonDecode(response.body);
        final latestVersion = releaseData['tag_name'].replaceAll('v', '');

        setState(() {
          _latestRelease = releaseData;
          _hasUpdate = _isNewerVersion(latestVersion, _currentVersion);
        });

        if (_hasUpdate) {
          _slideController.forward();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to check for updates: $e');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  Future<void> _downloadAndInstallUpdate() async {
    if (_latestRelease == null) return;

    int sdkInt = 30;
    if (Platform.isAndroid) {
      try {
        sdkInt = int.parse(
          (await File('/system/build.prop').readAsLines().then(
            (lines) => lines.firstWhere(
              (line) => line.startsWith('ro.build.version.sdk='),
              orElse: () => 'ro.build.version.sdk=30',
            ),
          )).split('=')[1],
        );
      } catch (_) {}
    }

    bool hasPermission = false;
    if (Platform.isAndroid) {
      if (sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        hasPermission = status.isGranted;
      } else {
        final status = await Permission.storage.request();
        hasPermission = status.isGranted;
      }
    } else {
      final status = await Permission.storage.request();
      hasPermission = status.isGranted;
    }

    if (!hasPermission) {
      _showErrorSnackBar(
        'Storage permission is required to download the update',
      );
      return;
    }

    if (!await Permission.requestInstallPackages.request().isGranted) {
      _showErrorSnackBar('Install permission is required to update the app');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final assets = _latestRelease!['assets'] as List;
      final apkAsset = assets.firstWhere(
        (asset) => asset['name'].toString().endsWith('.apk'),
        orElse: () => null,
      );

      if (apkAsset == null) {
        _showErrorSnackBar('No APK file found in the latest release');
        return;
      }

      final downloadUrl = apkAsset['browser_download_url'];
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final filePath = '${downloadsDir.path}/${apkAsset['name']}';

      final dio = Dio();
      final stopwatch = Stopwatch()..start();
      int lastBytes = 0;

      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          final progress = received / total;
          final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
          final bytesPerSecond =
              (received - lastBytes) /
              (elapsedSeconds == 0 ? 1 : elapsedSeconds);
          lastBytes = received;
          stopwatch.reset();

          setState(() {
            _downloadProgress = progress;
            _downloadSpeed = _formatSpeed(bytesPerSecond);
          });
        },
      );

      await _launchInstallerIntent(filePath);
    } catch (e) {
      _showErrorSnackBar('Download or install failed: $e');
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  Future<void> _launchInstallerIntent(String filePath) async {
    try {
      await InstallPluginV2Fork.installApk(filePath, 'com.playwaves.dark');
      // Refresh version after install
      await _getCurrentVersion();
      // Re-check for updates to reflect the new version
      await _checkForUpdates();
    } catch (e) {
      _showErrorSnackBar('Install failed: $e');
    }
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFFF4757),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildGlassCard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20,
    List<Color>? gradientColors,
    double blur = 15,
    double opacity = 0.08,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradientColors != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    )
                  : null,
              color: gradientColors == null
                  ? Colors.white.withOpacity(opacity)
                  : null,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _buildGlassCard(
            width: 74,
            height: 74,
            borderRadius: 14,
            gradientColors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'App Updates',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f0f23)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements (smaller)
            Positioned(
              top: -80,
              right: -80,
              child: AnimatedBuilder(
                animation: _breatheAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breatheAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6366f1).withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: AnimatedBuilder(
                animation: _breatheAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.2 - (_breatheAnimation.value - 0.95) * 2,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8b5cf6).withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildAppHeader(),
                    const SizedBox(height: 20),
                    _buildCheckButton(),
                    const SizedBox(height: 20),
                    if (_hasUpdate && _latestRelease != null)
                      Expanded(child: _buildUpdateCard()),
                    if (!_hasUpdate && !_isChecking) _buildUpToDateWidget(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return _buildGlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      gradientColors: [
        Colors.white.withOpacity(0.12),
        Colors.white.withOpacity(0.06),
      ],
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366f1),
                  Color(0xFF8b5cf6),
                  Color(0xFFa855f7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366f1).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PlayWaves',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version $_currentVersion',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton() {
    return _buildGlassCard(
      width: double.infinity,
      height: 52,
      gradientColors: [
        const Color(0xFF6366f1).withOpacity(0.8),
        const Color(0xFF8b5cf6).withOpacity(0.8),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isChecking ? null : _checkForUpdates,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isChecking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isChecking ? 'Checking...' : 'Check for Updates',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: _buildGlassCard(
        width: double.infinity,
        gradientColors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (more compact)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00d4aa),
                    Color(0xFF01a085),
                    Color(0xFF00b894),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🎉 Update Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${_latestRelease!['tag_name']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Content (more compact)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Release Info (smaller)
                    _buildGlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      borderRadius: 12,
                      gradientColors: [
                        const Color(0xFF6366f1).withOpacity(0.15),
                        const Color(0xFF8b5cf6).withOpacity(0.10),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Released ${_formatDate(_latestRelease!['published_at'])}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Changelog (smaller)
                    const Text(
                      'What\'s New',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildGlassCard(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        gradientColors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.04),
                        ],
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            _latestRelease!['body'] ??
                                'No release notes available.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Download Progress (smaller)
                    if (_isDownloading) ...[
                      _buildGlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        gradientColors: [
                          const Color(0xFF6366f1).withOpacity(0.15),
                          const Color(0xFF8b5cf6).withOpacity(0.10),
                        ],
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Downloading...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366f1),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6366f1),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _downloadSpeed,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Download Button (smaller)
                    _buildGlassCard(
                      width: double.infinity,
                      height: 48,
                      gradientColors: [
                        const Color(0xFF6366f1).withOpacity(0.9),
                        const Color(0xFF8b5cf6).withOpacity(0.9),
                      ],
                      borderRadius: 16,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isDownloading
                              ? null
                              : _downloadAndInstallUpdate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isDownloading
                                      ? Icons.downloading_rounded
                                      : Icons.download_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isDownloading
                                      ? 'Downloading...'
                                      : 'Download & Install',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildUpToDateWidget() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _breatheAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breatheAnimation.value,
                  child: _buildGlassCard(
                    width: 72,
                    height: 72,
                    borderRadius: 24,
                    gradientColors: [
                      const Color(0xFF00d4aa).withOpacity(0.9),
                      const Color(0xFF01a085).withOpacity(0.9),
                    ],
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'You\'re up to date! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _latestRelease != null
                  ? 'App already on latest version'
                  : 'Unable to check for updates',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
