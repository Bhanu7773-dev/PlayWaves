import 'package:flutter/material.dart';
import '../services/jiosaavn_api_service.dart';
import 'package:provider/provider.dart';
import '../services/player_state_provider.dart';

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
  }) : super(key: key);

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _showLyrics = false;
  PageController _pageController = PageController();

  final JioSaavnApiService _apiService = JioSaavnApiService();
  List<Map<String, dynamic>> _lyrics = [];
  bool _lyricsLoading = false;
  String? _lyricsError;

  @override
  void initState() {
    super.initState();
    if (widget.songId != null) {
      _fetchLyrics();
    }
  }

  Future<void> _fetchLyrics() async {
    if (widget.songId == null) {
      if (mounted) {
        setState(() {
          _lyrics = [
            {'time': 0, 'text': 'No song ID available'},
          ];
          _lyricsLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _lyricsLoading = true;
        _lyricsError = null;
      });
    }

    try {
      final songResponse = await _apiService.getSongById(widget.songId!);
      final songData = songResponse['data'];

      if (songData != null && songData.isNotEmpty) {
        final song = songData[0];
        final hasLyrics = song['hasLyrics'] ?? false;
        final lyricsId = song['lyricsId'];

        if (!hasLyrics || lyricsId == null) {
          if (mounted) {
            setState(() {
              _lyrics = [
                {'time': 0, 'text': 'Lyrics not available for this song'},
              ];
              _lyricsLoading = false;
            });
          }
          return;
        }
      }

      final response = await _apiService.getSongLyrics(widget.songId!);
      final lyricsData = response['data'];

      if (lyricsData != null && lyricsData['lyrics'] != null) {
        final lyricsText = lyricsData['lyrics'] as String;

        if (lyricsText.trim().isEmpty) {
          if (mounted) {
            setState(() {
              _lyrics = [
                {'time': 0, 'text': 'Lyrics not available for this song'},
              ];
              _lyricsLoading = false;
            });
          }
          return;
        }

        final lines = lyricsText.split('\n');

        if (mounted) {
          setState(() {
            _lyrics = lines
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'time': entry.key * 3,
                    'text': entry.value.trim(),
                  },
                )
                .where((lyric) => lyric['text'].toString().isNotEmpty)
                .toList();
            _lyricsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _lyrics = [
              {'time': 0, 'text': 'Lyrics not available for this song'},
            ];
            _lyricsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lyricsError = 'Failed to load lyrics: $e';
          _lyrics = [
            {'time': 0, 'text': 'Lyrics not available for this song'},
          ];
          _lyricsLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<PlayerStateProvider>(context);
    double progress = widget.totalDuration.inSeconds > 0
        ? widget.currentPosition.inSeconds / widget.totalDuration.inSeconds
        : 0.0;
    double displayProgress = _isDragging ? _dragValue : progress;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0x33ff7d78), Color(0x229c27b0), Colors.black],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
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
                    _buildIconBox(icon: Icons.more_vert, onPressed: () {}),
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
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Hero(
                            tag:
                                'album_art_${widget.songTitle}_${widget.artistName}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: widget.albumArtUrl.isNotEmpty
                                  ? Image.network(
                                      widget.albumArtUrl,
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
                      _buildLyricsView(),
                    ],
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
                          widget.songTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                          widget.artistName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLyrics = !_showLyrics;
                      });
                      _pageController.animateToPage(
                        _showLyrics ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
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
                            _showLyrics ? Icons.album : Icons.lyrics_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showLyrics ? 'Cover' : 'Lyrics',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        activeTrackColor: const Color(0xFFff7d78),
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: Colors.white,
                        overlayColor: const Color(0xFFff7d78).withOpacity(0.2),
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
                          widget.onSeek(value);
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
                                                widget.totalDuration.inSeconds)
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFff7d78).withOpacity(0.4),
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
                        onPressed: widget.isLoading ? null : widget.onPlayPause,
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

  Widget _buildLyricsView() {
    if (_lyricsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
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
    }

    if (_lyrics.isEmpty) {
      return Center(
        child: Text(
          _lyricsError ?? 'No lyrics available',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    int currentLyricIndex = 0;
    final currentSeconds = widget.currentPosition.inSeconds;

    for (int i = 0; i < _lyrics.length; i++) {
      final lyricTime = _lyrics[i]['time'];
      if (lyricTime is int && currentSeconds >= lyricTime) {
        currentLyricIndex = i;
      }
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lyrics',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _lyrics.length,
                  itemBuilder: (context, index) {
                    final isActive = index == currentLyricIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          fontSize: isActive ? 22 : 18,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          height: 1.6,
                        ),
                        child: Text(
                          _lyrics[index]['text'] as String,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
