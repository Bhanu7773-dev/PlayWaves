import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/player_state_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';
import '../models/liked_song.dart';
import '../models/playlist_song.dart';
import '../services/playlist_service.dart';
import 'package:just_audio/just_audio.dart';

// Decodes Unicode escapes in a string (e.g., \u0a38)
String decodeUnicodeEscapes(String input) {
  // Replace Unicode escapes with actual characters
  return input.replaceAllMapped(
    RegExp(r'\\u([0-9a-fA-F]{4})'),
    (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
  );
}

// LRC line model
class _LrcLine {
  final Duration timestamp;
  final String text;
  _LrcLine(this.timestamp, this.text);
}

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

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _meteorsController;
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  late Box<LikedSong> likedSongsBox;
  late Box<PlaylistSong> playlistSongsBox;
  bool _isInPlaylist = false;
  String? _lyrics;
  bool _lyricsLoading = false;
  String? _lyricsError;
  List<_LrcLine>? _syncedLyrics;
  int _currentLrcIndex = 0;
  bool _isDragging = false;
  double _dragValue = 0.0;
  final PageController _pageController = PageController();
  bool _isQueueOpen = false;
  static const int _queueTargetCount = 30;
  bool _isDownloading = false;
  bool _isLiked = false;

  // Lyrics scrolling related variables
  final ScrollController _lyricsScrollController = ScrollController();
  final GlobalKey _lyricsKey = GlobalKey();
  final Map<int, GlobalKey> _lyricsLineKeys = {};
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _meteorsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _likeScale = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_likeController);
    likedSongsBox = Hive.box<LikedSong>('likedSongs');
    playlistSongsBox = Hive.box<PlaylistSong>('playlistSongs');
    final playerState = Provider.of<PlayerStateProvider>(
      context,
      listen: false,
    );
    final songId =
        playerState.currentSong?['id'] ??
        playerState.currentSong?['songId'] ??
        '';
    _isInPlaylist = PlaylistService.isInPlaylist(songId);
    _fetchLyrics();
    _pageController.addListener(() {
      if (_pageController.page?.round() == 1 && _syncedLyrics != null && _syncedLyrics!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentLyric(_currentLrcIndex);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(MusicPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.songTitle != oldWidget.songTitle ||
        widget.artistName != oldWidget.artistName) {
      _fetchLyrics();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_syncedLyrics != null && _syncedLyrics!.isNotEmpty) {
        _updateLrcIndex(widget.currentPosition);
      }
    });
  }

  Future<void> _fetchLyrics() async {
    print(
      '[Lyrics] Fetching lyrics for artist: ${widget.artistName}, title: ${widget.songTitle}',
    );
    setState(() {
      _lyricsLoading = true;
      _lyricsError = null;
      _lyrics = null;
      _syncedLyrics = null;
      _currentLrcIndex = 0;
      _lyricsLineKeys.clear();
    });
    final artist = widget.artistName;
    final title = widget.songTitle;
    final url = Uri.parse(
      'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(artist)}&track_name=${Uri.encodeComponent(title)}',
    );
    print(
      '[Lyrics] API call URL: '
      'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(artist)}&track_name=${Uri.encodeComponent(title)}',
    );
    try {
      final response = await http.get(url);
      print('[Lyrics] Response status: ${response.statusCode}');
      print('[Lyrics] Response body length: ${response.body.length}');
      print(
        '[Lyrics] Response body (first 500): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );
      if (response.statusCode == 200) {
        final data = response.body;
        Map<String, dynamic> json;
        try {
          json = jsonDecode(data);
        } catch (e) {
          setState(() {
            _lyricsError = 'Error parsing lyrics response.';
            _lyricsLoading = false;
          });
          print('[Lyrics] JSON decode error: $e');
          return;
        }
        String? syncedLyrics = json['syncedLyrics'];
        String? plainLyrics = json['plainLyrics'];
        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          String lrcRaw = syncedLyrics.replaceAll(r'\n', '\n');
          print('[Lyrics] Extracted syncedLyrics length: ${lrcRaw.length}');
          print(
            '[Lyrics] syncedLyrics (first 200): ${lrcRaw.substring(0, lrcRaw.length > 200 ? 200 : lrcRaw.length)}',
          );
          print(
            '[Lyrics] syncedLyrics (last 200): ${lrcRaw.substring(lrcRaw.length > 200 ? lrcRaw.length - 200 : 0)}',
          );
          print('[Lyrics] Synced lyrics found. Parsing LRC...');
          final parsedLyrics = _parseLrc(lrcRaw);
          setState(() {
            _syncedLyrics = parsedLyrics;
            _lyricsLoading = false;
            // Initialize keys for each lyric line
            for (int i = 0; i < parsedLyrics.length; i++) {
              _lyricsLineKeys[i] = GlobalKey();
            }
          });
          print('[Lyrics] Parsed ${_syncedLyrics?.length ?? 0} LRC lines.');
        } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
          String decodedLyrics = plainLyrics.replaceAll(r'\n', '\n');
          setState(() {
            _lyrics = decodedLyrics;
            _lyricsLoading = false;
          });
          print('[Lyrics] Plain lyrics found.');
        } else {
          setState(() {
            _lyricsError = 'Lyrics not found.';
            _lyricsLoading = false;
          });
          print('[Lyrics] No lyrics found in response.');
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _lyricsError = 'Lyrics not found.';
          _lyricsLoading = false;
        });
        print('[Lyrics] API returned 404. Lyrics not found.');
      } else {
        setState(() {
          _lyricsError = 'Error fetching lyrics.';
          _lyricsLoading = false;
        });
        print('[Lyrics] API error. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _lyricsError = 'Error fetching lyrics.';
        _lyricsLoading = false;
      });
      print('[Lyrics] Exception: $e');
    }
  }

  List<_LrcLine> _parseLrc(String lrcRaw) {
    final lines = lrcRaw.split('\n');
    final lrcList = <_LrcLine>[];
    final timeExp = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\]');
    for (final line in lines) {
      final match = timeExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = match.group(3) != null
            ? int.parse(match.group(3)!.padRight(3, '0'))
            : 0;
        final time = Duration(minutes: min, seconds: sec, milliseconds: ms);
        final text = line.replaceAll(timeExp, '').trim();
        if (text.isNotEmpty) {
          // Only add non-empty lyrics
          lrcList.add(_LrcLine(time, text));
        }
      }
    }
    return lrcList;
  }

  void _updateLrcIndex(Duration position) {
    if (_syncedLyrics == null || _syncedLyrics!.isEmpty) return;
    int newIndex = 0;
    for (int i = 0; i < _syncedLyrics!.length; i++) {
      if (position >= _syncedLyrics![i].timestamp) {
        newIndex = i;
      } else {
        break;
      }
    }
    if (_currentLrcIndex != newIndex) {
      print(
        '[Lyrics] Updating current LRC index: $_currentLrcIndex -> $newIndex for position ${position.inMilliseconds}ms',
      );
      setState(() {
        _currentLrcIndex = newIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCurrentLyric(newIndex);
        }
      });
    }
  }

  void _scrollToCurrentLyric(int index) {
    if (_isAutoScrolling || !mounted) return;
    final key = _lyricsLineKeys[index];
    if (key?.currentContext != null) {
      _isAutoScrolling = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.5, // Center the line
          );
        } catch (e) {
          print('[Lyrics] Scrollable.ensureVisible error: $e');
        }
        if (mounted) _isAutoScrolling = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _meteorsController.dispose();
    _likeController.dispose();
    _lyricsScrollController.dispose();
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

  bool isLiked(String songId) {
    return likedSongsBox.containsKey(songId);
  }

  void toggleLike(Map<String, dynamic> song) {
    final songId = song['id'] ?? song['title'];
    if (isLiked(songId)) {
      likedSongsBox.delete(songId);
    } else {
      String imageUrl = '';
      final img = song['image'];
      if (img is List && img.isNotEmpty) {
        for (var item in img) {
          if (item is Map &&
              item['link'] != null &&
              item['link'].toString().contains('500x500')) {
            imageUrl = item['link'];
            break;
          }
        }
        if (imageUrl.isEmpty) {
          for (var item in img.reversed) {
            if (item is Map &&
                item['link'] != null &&
                item['link'].toString().isNotEmpty) {
              imageUrl = item['link'];
              break;
            }
            if (item is Map &&
                item['url'] != null &&
                item['url'].toString().isNotEmpty) {
              imageUrl = item['url'];
              break;
            }
          }
        }
        if (imageUrl.isEmpty && img.last is Map && img.last['link'] != null) {
          imageUrl = img.last['link'];
        }
      } else if (img is String && img.isNotEmpty) {
        imageUrl = img;
      }
      String artistName = '';
      if (song['artists'] != null &&
          song['artists'] is Map &&
          song['artists']['primary'] is List &&
          (song['artists']['primary'] as List).isNotEmpty) {
        artistName = song['artists']['primary'][0]['name'] ?? '';
      } else if (song['primaryArtists'] != null &&
          song['primaryArtists'].toString().isNotEmpty) {
        artistName = song['primaryArtists'];
      } else if (song['subtitle'] != null &&
          song['subtitle'].toString().isNotEmpty) {
        artistName = song['subtitle'];
      }
      String downloadUrl = '';
      if (song['downloadUrl'] != null &&
          song['downloadUrl'] is List &&
          (song['downloadUrl'] as List).isNotEmpty) {
        final urlObj = (song['downloadUrl'] as List).last;
        if (urlObj is Map && urlObj['url'] != null) {
          downloadUrl = urlObj['url'];
        }
      } else if (song['media_url'] != null) {
        downloadUrl = song['media_url'];
      } else if (song['media_preview_url'] != null) {
        downloadUrl = song['media_preview_url'];
      }
      likedSongsBox.put(
        songId,
        LikedSong(
          id: songId,
          title: song['name'] ?? song['title'] ?? '',
          artist: artistName,
          imageUrl: imageUrl,
          downloadUrl: downloadUrl,
        ),
      );
    }
    setState(() {});
  }

  Widget _lyricsWidget(
    BuildContext context,
    CustomThemeProvider customTheme,
    bool customColorsEnabled,
    Color primaryColor,
  ) {
    final audioPlayer = Provider.of<AudioPlayer>(context, listen: false);

    // Tweak this value for lyric timing offset (in ms, negative means show earlier)
    const int lyricsOffsetMs = 20;

    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      builder: (context, snapshot) {
        // Apply offset for better sync
        final position =
            (snapshot.data ?? Duration.zero) +
            Duration(milliseconds: lyricsOffsetMs);

        int lrcIndex = 0;
        if (_syncedLyrics != null && _syncedLyrics!.isNotEmpty) {
          // Robust index calculation (handles skips and seeks)
          for (int i = 0; i < _syncedLyrics!.length; i++) {
            if (position >= _syncedLyrics![i].timestamp) {
              lrcIndex = i;
            } else {
              break;
            }
          }
          if (_currentLrcIndex != lrcIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _currentLrcIndex = lrcIndex;
              });
              _scrollToCurrentLyric(lrcIndex);
            });
          }
        }

        if (_lyricsLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: customColorsEnabled ? primaryColor : Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading lyrics...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        } else if (_lyricsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  color: Colors.white.withOpacity(0.5),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _lyricsError!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (_syncedLyrics != null && _syncedLyrics!.isNotEmpty) {
          return Expanded(
            child: Scrollbar(
              controller: _lyricsScrollController,
              thumbVisibility: false,
              child: ListView.builder(
                key: _lyricsKey,
                controller: _lyricsScrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 100,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _syncedLyrics!.length,
                itemBuilder: (context, idx) {
                  final line = _syncedLyrics![idx];
                  final isCurrent = idx == _currentLrcIndex;
                  return Container(
                    key: _lyricsLineKeys[idx],
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: isCurrent
                            ? (customColorsEnabled
                                  ? primaryColor
                                  : Colors.white)
                            : Colors.white.withOpacity(0.6),
                        fontSize: isCurrent ? 22 : 18,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                        height: 1.4,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCurrent ? 8 : 0,
                          vertical: isCurrent ? 8 : 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isCurrent
                              ? (customColorsEnabled
                                    ? primaryColor.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.05))
                              : Colors.transparent,
                        ),
                        child: Text(
                          line.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            shadows: isCurrent
                                ? [
                                    Shadow(
                                      color:
                                          (customColorsEnabled
                                                  ? primaryColor
                                                  : Colors.white)
                                              .withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (_lyrics != null) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No synced lyrics available for this song',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      _lyrics!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lyrics_outlined,
                  color: Colors.white.withOpacity(0.3),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lyrics will appear here',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Swipe to see album art',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;
    final primaryColor = customColorsEnabled
        ? customTheme.primaryColor
        : const Color(0xFFff7d78);
    final secondaryColor = customColorsEnabled
        ? customTheme.secondaryColor
        : Colors.black;

    final double progress = widget.totalDuration.inSeconds > 0
        ? (widget.currentPosition.inSeconds / widget.totalDuration.inSeconds)
              .clamp(0.0, 1.0)
        : 0.0;
    final double displayProgress = _isDragging ? _dragValue : progress;

    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;

    return Scaffold(
      backgroundColor: isPitchBlack
          ? Colors.black
          : customColorsEnabled
          ? customTheme.secondaryColor
          : const Color(0xFF0F0F23),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -10) {
            _showUpNextQueue(context);
          }
        },
        child: Stack(
          children: [
            _buildAnimatedBackground(isPitchBlack: isPitchBlack),
            SafeArea(
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

                  final songId = song?['id'] ?? song?['title'];
                  final actuallyLiked = songId != null
                      ? isLiked(songId)
                      : false;
                  if (_isLiked != actuallyLiked) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted)
                        setState(() {
                          _isLiked = actuallyLiked;
                        });
                    });
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
                            customColorsEnabled
                                ? Text(
                                    'Now Playing',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  )
                                : ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFFff7d78),
                                            Color(0xFF9c27b0),
                                          ],
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
                          child: PageView(
                            controller: _pageController,
                            children: [
                              Center(
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
                                                      child: Icon(
                                                        Icons.music_note,
                                                        color:
                                                            customColorsEnabled
                                                            ? primaryColor
                                                            : Colors.white,
                                                        size: 80,
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Container(
                                              color: Colors.grey[800],
                                              child: Icon(
                                                Icons.music_note,
                                                color: customColorsEnabled
                                                    ? primaryColor
                                                    : Colors.white,
                                                size: 80,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              // Lyrics Page
                              Container(
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lyrics,
                                            size: 20,
                                            color: customColorsEnabled
                                                ? primaryColor
                                                : Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Lyrics',
                                            style: TextStyle(
                                              color: customColorsEnabled
                                                  ? primaryColor
                                                  : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _lyricsWidget(
                                      context,
                                      customTheme,
                                      customColorsEnabled,
                                      primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    final playerState =
                                        Provider.of<PlayerStateProvider>(
                                          context,
                                          listen: false,
                                        );
                                    final song = playerState.currentSong;
                                    if (song == null) return;
                                    toggleLike(song);
                                    final songId = song['id'] ?? song['title'];
                                    final nowLiked = isLiked(songId);
                                    setState(() {
                                      _isLiked = nowLiked;
                                    });
                                    if (!_likeController.isAnimating) {
                                      if (_isLiked) {
                                        _likeController.forward(from: 0);
                                      } else {
                                        _likeController.reverse();
                                      }
                                    }
                                  },
                                  child: AnimatedBuilder(
                                    animation: _likeController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _isLiked
                                            ? _likeScale.value
                                            : 1.0,
                                        child: _isLiked
                                            ? (customColorsEnabled
                                                  ? Icon(
                                                      Icons.favorite,
                                                      color: primaryColor,
                                                      size: 28,
                                                    )
                                                  : ShaderMask(
                                                      shaderCallback:
                                                          (Rect bounds) {
                                                            return const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFFff7d78,
                                                                ),
                                                                Color(
                                                                  0xFF9c27b0,
                                                                ),
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ).createShader(
                                                              bounds,
                                                            );
                                                          },
                                                      child: const Icon(
                                                        Icons.favorite,
                                                        color: Colors.white,
                                                        size: 28,
                                                      ),
                                                    ))
                                            : const Icon(
                                                Icons.favorite_border,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('More Options'),
                                          content: const Text(
                                            'Add items here later.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
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
                              GestureDetector(
                                onTap: () {
                                  final playerState =
                                      Provider.of<PlayerStateProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final song = playerState.currentSong;
                                  if (song != null) {
                                    PlaylistService.addToPlaylist(song);
                                    setState(() {
                                      final songId =
                                          song['id'] ?? song['songId'] ?? '';
                                      _isInPlaylist =
                                          PlaylistService.isInPlaylist(songId);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added to My Playlist'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
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
                                        _isInPlaylist
                                            ? Icons.playlist_add_check
                                            : Icons.playlist_add,
                                        color: _isInPlaylist
                                            ? Colors.greenAccent
                                            : Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isInPlaylist
                                            ? 'Added'
                                            : 'Add to Playlist',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                            color: Colors.white,
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
                                          color: Colors.white,
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
                                inactiveTrackColor: Colors.white.withOpacity(
                                  0.2,
                                ),
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
                                color: customColorsEnabled
                                    ? primaryColor
                                    : null,
                                gradient: !customColorsEnabled
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFff7d78),
                                          Color(0xFF9c27b0),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: IconButton(
                                icon: widget.isLoading
                                    ? SizedBox(
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
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground({required bool isPitchBlack}) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;

    return Container(
      decoration: isPitchBlack
          ? const BoxDecoration(color: Colors.black)
          : customColorsEnabled
          ? BoxDecoration(color: customTheme.secondaryColor)
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0F23),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F0F23),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
      child: Stack(
        children: [
          ...List.generate(
            50,
            (index) => _buildStaticStar(index, isPitchBlack: isPitchBlack),
          ),
          ...List.generate(
            15,
            (index) => _buildMeteor(index, isPitchBlack: isPitchBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticStar(int index, {required bool isPitchBlack}) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;

    final List<Color> starColors = [
      Colors.white.withOpacity(0.8),
      Colors.blue.shade100.withOpacity(0.6),
      Colors.purple.shade100.withOpacity(0.5),
      const Color(0xFFFFE5B4).withOpacity(0.7),
    ];

    final starColor = customColorsEnabled
        ? customTheme.primaryColor.withOpacity(0.6)
        : starColors[index % starColors.length];

    return Positioned(
      top: (index * 37.0) % MediaQuery.of(context).size.height,
      left: (index * 73.0) % MediaQuery.of(context).size.width,
      child: Opacity(
        opacity: isPitchBlack ? 0 : (0.3 + (index % 3) * 0.2),
        child: Container(
          width: 1.5 + (index % 3) * 0.5,
          height: 1.5 + (index % 3) * 0.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: starColor,
            boxShadow: [
              BoxShadow(
                color: starColor.withOpacity(0.5),
                blurRadius: 2,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeteor(int index, {required bool isPitchBlack}) {
    final customTheme = context.watch<CustomThemeProvider>();
    final customColorsEnabled = customTheme.customColorsEnabled;

    final List<Color> meteorColors = [
      const Color(0xFFFFE5B4),
      const Color(0xFFB8E6FF),
      const Color(0xFFE6B8FF),
      Colors.white,
    ];

    final meteorColor = customColorsEnabled
        ? customTheme.primaryColor
        : meteorColors[index % meteorColors.length];

    return AnimatedBuilder(
      animation: _meteorsController,
      builder: (context, child) {
        final double progress = _meteorsController.value;
        final double staggeredProgress = ((progress + (index * 0.15)) % 1.0)
            .clamp(0.0, 1.0);
        return Positioned(
          top: (index * 80.0) % MediaQuery.of(context).size.height,
          left: (index * 120.0) % MediaQuery.of(context).size.width,
          child: Transform.translate(
            offset: Offset(
              staggeredProgress * 150 - 75,
              staggeredProgress * 150 - 75,
            ),
            child: Opacity(
              opacity: isPitchBlack ? 0 : (1.0 - staggeredProgress) * 0.8,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: meteorColor,
                  boxShadow: [
                    BoxShadow(
                      color: meteorColor.withOpacity(0.6),
                      blurRadius: 8,
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
