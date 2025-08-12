import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/jiosaavn_api_service.dart';
import '../services/player_state_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart'; // <-- Import your custom theme provider

class MusicPlayerPage extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String albumArtUrl;
  final bool isPlaying;
  final bool isLoading;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<double> onSeek;
  final String? songId;
  final Function(int)? onJumpToSong;

  const MusicPlayerPage({
    Key? key,
    required this.songTitle,
    required this.artistName,
    required this.albumArtUrl,
    required this.isPlaying,
    this.isLoading = false,
    required this.currentPosition,
    required this.totalDuration,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    this.songId,
    this.onJumpToSong,
  }) : super(key: key);

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  final PageController _pageController = PageController();

  final JioSaavnApiService _apiService = JioSaavnApiService();

  bool _isQueueOpen = false;
  static const int _queueTargetCount = 30;
  bool _isDownloading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrentSong() async {
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final song = playerState.currentSong;
    final rawQuality = playerState.downloadQuality ?? "320kbps";
    final quality = _normalizeQuality(rawQuality);

    String? downloadUrl;
    if (song != null &&
        song['downloadUrl'] != null &&
        song['downloadUrl'] is List) {
      final urlObj = (song['downloadUrl'] as List).firstWhere(
        (item) =>
            item is Map &&
            item['quality'] != null &&
            item['quality'].toString().trim().toLowerCase() ==
                quality.trim().toLowerCase(),
        orElse: () => null,
      );
      if (urlObj != null && urlObj is Map) {
        downloadUrl = urlObj['url'];
      }
    }

    downloadUrl ??= song?['media_preview_url'] ?? song?['media_url'];

    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No download URL found for $quality")),
      );
      return;
    }

    bool hasPermission = false;
    if (Platform.isAndroid) {
      int sdkInt = 30;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Storage permission denied")));
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    Directory? dir;
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      dir = dirs?.first;
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    if (dir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not access save directory")),
      );
      setState(() {
        _isDownloading = false;
      });
      return;
    }

    String fileName =
        "${song?['name']} - ${song?['artists'] != null && song?['artists']?['primary'] != null && (song?['artists']?['primary'] as List?)?.isNotEmpty == true ? (song?['artists']?['primary'] as List)[0]['name'] : 'Unknown'} [$quality].mp3";
    fileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), "_");
    final filePath = "${dir.path}/$fileName";

    try {
      await Dio().download(downloadUrl, filePath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Downloaded to $filePath")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download failed: $e")));
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ---- Custom theme logic here ----
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customColorsEnabled
        ? customTheme.primaryColor
        : Color(0xFFff7d78);
    final secondaryColor = customColorsEnabled
        ? customTheme.secondaryColor
        : Color(0xFF16213e);
    final gradientColors = customColorsEnabled
        ? [primaryColor, secondaryColor, Colors.black]
        : [Color(0x33ff7d78), Color(0x229c27b0), Colors.black];

    final double progress = widget.totalDuration.inSeconds > 0
        ? (widget.currentPosition.inSeconds / widget.totalDuration.inSeconds)
              .clamp(0.0, 1.0)
        : 0.0;
    final double displayProgress = _isDragging ? _dragValue : progress;

    final isPitchBlack = context
        .watch<PitchBlackThemeProvider>()
        .isPitchBlack; // <-- Read theme

    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : secondaryColor,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -10) {
            _showUpNextQueue(context);
          }
        },
        child: Container(
          decoration: isPitchBlack
              ? const BoxDecoration(color: Colors.black)
              : BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.5,
                    colors: gradientColors,
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
          child: SafeArea(
            child: Consumer<PlayerStateProvider>(
              builder: (context, playerState, child) {
                final song = playerState.currentSong;
                final String currentSongTitle =
                    song?['name'] ?? song?['title'] ?? widget.songTitle;

                String currentArtistName = 'Unknown Artist';
                if (song?['artists'] != null) {
                  final artists = song!['artists'];
                  if (artists is Map &&
                      artists['primary'] is List &&
                      artists['primary'].isNotEmpty) {
                    currentArtistName =
                        artists['primary'][0]['name'] ?? 'Unknown Artist';
                  }
                } else if (song?['primaryArtists'] != null) {
                  currentArtistName =
                      song!['primaryArtists'] ?? widget.artistName;
                } else if (song?['subtitle'] != null) {
                  currentArtistName = song!['subtitle'] ?? widget.artistName;
                } else {
                  currentArtistName = widget.artistName;
                }

                String currentAlbumArtUrl = '';
                if (song?['image'] != null) {
                  currentAlbumArtUrl = _getBestImageUrl(song!['image']);
                }
                if (currentAlbumArtUrl.isEmpty) {
                  currentAlbumArtUrl = widget.albumArtUrl;
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildIconBox(
                            icon: Icons.keyboard_arrow_down,
                            onPressed: () => Navigator.pop(context),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            ).createShader(bounds),
                            child: const Text(
                              'Now Playing',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _buildIconBox(
                            icon: Icons.queue_music,
                            onPressed: () => _showUpNextQueue(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.40,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Hero(
                              tag:
                                  'album_art_${widget.songTitle}_${widget.artistName}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: currentAlbumArtUrl.isNotEmpty
                                    ? Image.network(
                                        currentAlbumArtUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[800],
                                                child: const Icon(
                                                  Icons.music_note,
                                                  color: Colors.white,
                                                  size: 80,
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 80,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 18),
                          Hero(
                            tag:
                                'song_title_${widget.songTitle}_${widget.artistName}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                currentSongTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Hero(
                            tag:
                                'artist_name_${widget.songTitle}_${widget.artistName}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                currentArtistName,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.playlist_add,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add to Playlist',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isDownloading
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.download,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 18,
                                        ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _isDownloading
                                        ? null
                                        : _downloadCurrentSong,
                                    child: Text(
                                      'Download',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
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
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              activeTrackColor: primaryColor,
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                              thumbColor: Colors.white,
                              overlayColor: primaryColor.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: displayProgress.clamp(0.0, 1.0),
                              min: 0.0,
                              max: 1.0,
                              onChangeStart: (value) {
                                setState(() {
                                  _isDragging = true;
                                  _dragValue = value;
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  _dragValue = value;
                                });
                              },
                              onChangeEnd: (value) {
                                setState(() {
                                  _isDragging = false;
                                });
                                widget.onSeek(value.clamp(0.0, 1.0));
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                  _isDragging
                                      ? Duration(
                                          seconds:
                                              (_dragValue *
                                                      widget
                                                          .totalDuration
                                                          .inSeconds)
                                                  .round(),
                                        )
                                      : widget.currentPosition,
                                ),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatDuration(widget.totalDuration),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildIconBox(
                            icon: Icons.skip_previous,
                            size: 32,
                            onPressed: widget.onPrevious,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: widget.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      widget.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                              onPressed: widget.isLoading
                                  ? null
                                  : widget.onPlayPause,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          _buildIconBox(
                            icon: Icons.skip_next,
                            size: 32,
                            onPressed: widget.onNext,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox({
    required IconData icon,
    double size = 28,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showUpNextQueue(BuildContext context) async {
    if (_isQueueOpen) return;
    _isQueueOpen = true;

    try {
      final ps = Provider.of<PlayerStateProvider>(context, listen: false);
      final List<dynamic> playlistAtOpen = (ps.currentPlaylist ?? []) as List;
      final int currentAtOpen = (ps.currentSongIndex < 0)
          ? 0
          : ps.currentSongIndex;

      final List<int> indices = _buildRandomQueueIndices(
        playlistAtOpen.length,
        min(
          currentAtOpen,
          playlistAtOpen.isEmpty ? 0 : playlistAtOpen.length - 1,
        ),
        _queueTargetCount,
      );

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder: (context, scrollController) {
              return Consumer<PlayerStateProvider>(
                builder: (ctx, playerState, _) {
                  final playlist = playerState.currentPlaylist ?? [];
                  if (playlist.isEmpty || indices.isEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Up Next',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Queue is empty',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(
                            'Up Next',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: indices.length,
                            itemBuilder: (context, index) {
                              final effectiveIndex = indices[index];

                              if (effectiveIndex < 0 ||
                                  effectiveIndex >= playlist.length) {
                                return const SizedBox.shrink();
                              }

                              final song = playlist[effectiveIndex];
                              final imageUrl = _getBestImageUrl(song['image']);

                              String subtitle = 'Unknown';
                              final artists = song['artists'];
                              if (artists is Map &&
                                  artists['primary'] is List &&
                                  (artists['primary'] as List).isNotEmpty) {
                                subtitle =
                                    artists['primary'][0]['name'] ?? 'Unknown';
                              } else if (song['primaryArtists'] is String &&
                                  (song['primaryArtists'] as String)
                                      .isNotEmpty) {
                                subtitle = song['primaryArtists'];
                              } else if (song['subtitle'] is String &&
                                  (song['subtitle'] as String).isNotEmpty) {
                                subtitle = song['subtitle'];
                              }

                              final bool isCurrent =
                                  effectiveIndex ==
                                  playerState.currentSongIndex;

                              return ListTile(
                                selected: isCurrent,
                                selectedTileColor: Colors.white.withOpacity(
                                  0.06,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: Colors.grey[800],
                                                    child: const Icon(
                                                      Icons.music_note,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  song['name'] ?? song['title'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: isCurrent
                                    ? Icon(
                                        Icons.graphic_eq,
                                        color: Colors.greenAccent.shade400,
                                      )
                                    : null,
                                onTap: () {
                                  if (!isCurrent) {
                                    _jumpToSong(effectiveIndex);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Failed to open Up Next sheet: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isQueueOpen = false;
        });
      } else {
        _isQueueOpen = false;
      }
    }
  }

  List<int> _buildRandomQueueIndices(
    int playlistLength,
    int currentIndex,
    int targetCount,
  ) {
    if (playlistLength <= 0) return [];
    final rand = Random();

    final int safeCurrent = playlistLength == 0
        ? 0
        : currentIndex.clamp(0, max(0, playlistLength - 1));

    final result = <int>[safeCurrent];

    final pool = List<int>.generate(playlistLength, (i) => i)
      ..remove(safeCurrent);

    while (result.length < targetCount) {
      if (pool.isEmpty) {
        if (playlistLength <= 1) break;
        pool.addAll(
          List<int>.generate(playlistLength, (i) => i)..remove(safeCurrent),
        );
      }
      final pick = pool.removeAt(rand.nextInt(pool.length));
      if (result.isEmpty || result.last != pick) {
        result.add(pick);
      }
    }

    return result.take(targetCount).toList();
  }

  String _getBestImageUrl(dynamic images) {
    if (images is List && images.isNotEmpty) {
      for (var img in images.reversed) {
        if (img is Map &&
            img['link'] is String &&
            (img['link'] as String).isNotEmpty) {
          return img['link'];
        }
        if (img is Map &&
            img['url'] is String &&
            (img['url'] as String).isNotEmpty) {
          return img['url'];
        }
      }
    } else if (images is String && images.isNotEmpty) {
      return images;
    }
    return '';
  }

  void _jumpToSong(int index) {
    if (widget.onJumpToSong != null) {
      widget.onJumpToSong!(index);
    }
  }

  String _normalizeQuality(String rawQuality) {
    final q = rawQuality.trim().toLowerCase();
    if (q.contains('320')) return '320kbps';
    if (q.contains('160')) return '160kbps';
    if (q.contains('96')) return '96kbps';
    if (q.contains('48')) return '48kbps';
    if (q.contains('12')) return '12kbps';
    return '320kbps';
  }
}
