import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/liked_song.dart';
import '../services/pitch_black_theme_provider.dart';
import '../services/custom_theme_provider.dart';
import '../services/player_state_provider.dart';
import 'music_player.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({Key? key}) : super(key: key);

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _meteorController;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<int?>? _currentIndexSub;
  late AudioPlayer audioPlayer;
  late PlayerStateProvider playerState;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _meteorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _fadeController.forward();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      audioPlayer = Provider.of<AudioPlayer>(context, listen: false);
      playerState = Provider.of<PlayerStateProvider>(context, listen: false);

      _playingSub = audioPlayer.playingStream.listen((playing) {
        playerState.setPlaying(playing);
        if (mounted && !_isDisposed) setState(() {});
      });

      _currentIndexSub = audioPlayer.currentIndexStream.listen((index) {
        final likedSongs = Hive.box<LikedSong>('likedSongs').values.toList();
        if (playerState.currentContext == "liked" &&
            index != null &&
            index >= 0 &&
            index < likedSongs.length) {
          playerState.setSongIndex(index);
          playerState.setSong({
            'id': likedSongs[index].id,
            'name': likedSongs[index].title,
            'primaryArtists': likedSongs[index].artist,
            'image': likedSongs[index].imageUrl,
            'downloadUrl': likedSongs[index].downloadUrl,
          });
          if (mounted && !_isDisposed) setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fadeController.dispose();
    _meteorController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _playingSub?.cancel();
    _currentIndexSub?.cancel();
    super.dispose();
  }

  void _syncPlayerState() {
    playerState.setPlaying(audioPlayer.playing);
    if (mounted && !_isDisposed) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncPlayerState();
    }
  }

  Future<void> _playLikedSong(
    LikedSong song,
    int index,
    List<LikedSong> likedSongs,
  ) async {
    try {
      playerState.setSongLoading(true);

      // Build liked songs playlist
      final sources = likedSongs
          .map(
            (s) => AudioSource.uri(
              Uri.parse(s.downloadUrl ?? ''),
              tag: MediaItem(
                id: s.id,
                album: '',
                title: s.title,
                artist: s.artist,
                artUri: s.imageUrl.isNotEmpty ? Uri.parse(s.imageUrl) : null,
              ),
            ),
          )
          .toList();

      final playlistSource = ConcatenatingAudioSource(children: sources);

      playerState.setPlaylist(
        likedSongs
            .map(
              (s) => {
                'id': s.id,
                'name': s.title,
                'primaryArtists': s.artist,
                'image': s.imageUrl,
                'downloadUrl': s.downloadUrl,
              },
            )
            .toList(),
      );
      playerState.setSongIndex(index);
      playerState.setSong({
        'id': song.id,
        'name': song.title,
        'primaryArtists': song.artist,
        'image': song.imageUrl,
        'downloadUrl': song.downloadUrl,
      });

      // Mark context as liked
      playerState.setCurrentContext("liked");

      await audioPlayer.setAudioSource(playlistSource, initialIndex: index);
      await audioPlayer.play();
      playerState.setPlaying(true);
      playerState.setSongLoading(false);
    } catch (e) {
      playerState.setSongLoading(false);
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing song: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
    if (mounted && !_isDisposed) setState(() {});
  }

  void _openMusicPlayer(
    LikedSong song,
    int index,
    List<LikedSong> likedSongs,
  ) async {
    final isCurrentSong =
        playerState.currentSong != null &&
        playerState.currentSong!['id'] == song.id &&
        playerState.currentContext == "liked";

    if (!isCurrentSong) {
      await _playLikedSong(song, index, likedSongs);
    }

    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => StreamBuilder<bool>(
              stream: audioPlayer.playingStream,
              builder: (context, playingSnapshot) {
                return StreamBuilder<Duration>(
                  stream: audioPlayer.positionStream,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration?>(
                      stream: audioPlayer.durationStream,
                      builder: (context, durationSnapshot) {
                        return MusicPlayerPage(
                          songTitle: song.title,
                          artistName: song.artist,
                          albumArtUrl: song.imageUrl,
                          songId: song.id,
                          isPlaying: playingSnapshot.data ?? false,
                          isLoading: playerState.isSongLoading,
                          currentPosition:
                              positionSnapshot.data ?? Duration.zero,
                          totalDuration: durationSnapshot.data ?? Duration.zero,
                          onPlayPause: () {
                            if (audioPlayer.playing) {
                              audioPlayer.pause();
                            } else {
                              audioPlayer.play();
                            }
                          },
                          onNext: () async {
                            final currentIndex = likedSongs.indexWhere(
                              (s) => s.id == song.id,
                            );
                            if (currentIndex != -1 &&
                                currentIndex < likedSongs.length - 1) {
                              await _playLikedSong(
                                likedSongs[currentIndex + 1],
                                currentIndex + 1,
                                likedSongs,
                              );
                            }
                          },
                          onPrevious: () async {
                            final currentIndex = likedSongs.indexWhere(
                              (s) => s.id == song.id,
                            );
                            if (currentIndex > 0) {
                              await _playLikedSong(
                                likedSongs[currentIndex - 1],
                                currentIndex - 1,
                                likedSongs,
                              );
                            }
                          },
                          onJumpToSong: (jumpIndex) async {
                            if (jumpIndex >= 0 &&
                                jumpIndex < likedSongs.length) {
                              await _playLikedSong(
                                likedSongs[jumpIndex],
                                jumpIndex,
                                likedSongs,
                              );
                            }
                          },
                          onSeek: (value) {
                            final position =
                                (durationSnapshot.data ?? Duration.zero) *
                                value;
                            audioPlayer.seek(position);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        )
        .then((_) {
          if (mounted && !_isDisposed) setState(() {});
        });
  }

  Widget _buildSongCard(
    LikedSong song,
    int index,
    List<LikedSong> likedSongs,
    bool isCurrentSong,
    bool isPlaying,
    bool isLoading,
    bool customColorsEnabled,
    Color primaryColor,
    Color secondaryColor,
    VoidCallback onDelete,
  ) {
    final shouldShowPause =
        isCurrentSong && isPlaying && playerState.currentContext == "liked";
    final showLoader =
        isCurrentSong && isLoading && playerState.currentContext == "liked";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openMusicPlayer(song, index, likedSongs),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: customColorsEnabled
                                ? [
                                    primaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.1),
                                  ]
                                : [
                                    Color(0xFFff7d78).withOpacity(0.3),
                                    Color(0xFF9c27b0).withOpacity(0.3),
                                  ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: song.imageUrl.isNotEmpty
                              ? Image.network(
                                  song.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.music_note,
                                      color: customColorsEnabled
                                          ? primaryColor
                                          : Color(0xFFff7d78),
                                      size: 24,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.music_note,
                                  color: customColorsEnabled
                                      ? primaryColor
                                      : Color(0xFFff7d78),
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: TextStyle(
                                color: customColorsEnabled
                                    ? primaryColor
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    song.artist,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: customColorsEnabled
                          ? [primaryColor, primaryColor.withOpacity(0.8)]
                          : [Color(0xFFff7d78), Color(0xFF9c27b0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: customColorsEnabled
                            ? primaryColor.withOpacity(0.4)
                            : Color(0xFFff7d78).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: showLoader
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            shouldShowPause ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                    onPressed: showLoader
                        ? null
                        : () async {
                            if (isCurrentSong && shouldShowPause) {
                              await audioPlayer.pause();
                              playerState.setPlaying(false);
                            } else if (isCurrentSong && !shouldShowPause) {
                              await audioPlayer.play();
                              playerState.setPlaying(true);
                            } else {
                              await _playLikedSong(song, index, likedSongs);
                            }
                            if (mounted && !_isDisposed) setState(() {});
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: onDelete,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool customColorsEnabled,
    required Color primaryColor,
  }) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: customColorsEnabled
                      ? [
                          primaryColor.withOpacity(0.3),
                          primaryColor.withOpacity(0.1),
                        ]
                      : [
                          Color(0xFFff7d78).withOpacity(0.3),
                          Color(0xFF9c27b0).withOpacity(0.3),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: customColorsEnabled ? primaryColor : Color(0xFFff7d78),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Liked Songs Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start exploring music and like\nyour favorite tracks!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: customColorsEnabled
                      ? [primaryColor, primaryColor.withOpacity(0.8)]
                      : [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: customColorsEnabled
                        ? primaryColor.withOpacity(0.4)
                        : Color(0xFFff7d78).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Explore Music',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildAnimatedBackground({
    required bool isPitchBlack,
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPitchBlack
            ? null
            : customColorsEnabled
            ? RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  secondaryColor,
                  secondaryColor.withOpacity(0.8),
                  Colors.black,
                ],
              )
            : const RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Colors.black],
              ),
        color: isPitchBlack ? Colors.black : null,
      ),
      child: Stack(
        children: List.generate(
          8,
          (index) =>
              _buildMeteor(index, customColorsEnabled ? primaryColor : null),
        ),
      ),
    );
  }

  Widget _buildMeteor(int index, [Color? meteorColor]) {
    return AnimatedBuilder(
      animation: _meteorController,
      builder: (context, child) {
        final offset = _meteorController.value * 2 - 1;
        return Positioned(
          top:
              (index * 80.0 + offset * 120) %
              MediaQuery.of(context).size.height,
          left: (index * 110.0) % MediaQuery.of(context).size.width,
          child: Transform.rotate(
            angle: 3.14159 * 1.2,
            child: Container(
              width: 2,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: meteorColor != null
                      ? [
                          meteorColor.withOpacity(0.8),
                          meteorColor.withOpacity(0.3),
                          Colors.transparent,
                        ]
                      : [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
    required int songsCount,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: customColorsEnabled
                            ? [primaryColor, primaryColor.withOpacity(0.8)]
                            : [Color(0xFFff7d78), Color(0xFF9c27b0)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$songsCount Songs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: customColorsEnabled
                            ? [primaryColor, primaryColor.withOpacity(0.7)]
                            : [Color(0xFFff7d78), Color(0xFF9c27b0)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: customColorsEnabled
                                      ? [
                                          primaryColor.withOpacity(0.3),
                                          primaryColor.withOpacity(0.1),
                                        ]
                                      : [
                                          Color(0xFFff7d78).withOpacity(0.3),
                                          Color(0xFF9c27b0).withOpacity(0.3),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: customColorsEnabled
                                    ? primaryColor
                                    : Color(0xFFff7d78),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Liked Songs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your favorite tracks',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, _) {
        final likedSongsBox = Hive.box<LikedSong>('likedSongs');
        final isPitchBlack = context
            .watch<PitchBlackThemeProvider>()
            .isPitchBlack;
        final customTheme = context.watch<CustomThemeProvider>();
        final customColorsEnabled = customTheme.customColorsEnabled;
        final primaryColor = customColorsEnabled
            ? customTheme.primaryColor
            : const Color(0xFFff7d78);
        final secondaryColor = customColorsEnabled
            ? customTheme.secondaryColor
            : const Color(0xFF16213e);

        return Scaffold(
          backgroundColor: isPitchBlack ? Colors.black : secondaryColor,
          body: Stack(
            children: [
              _buildAnimatedBackground(
                isPitchBlack: isPitchBlack,
                customColorsEnabled: customColorsEnabled,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              ValueListenableBuilder(
                valueListenable: likedSongsBox.listenable(),
                builder: (context, Box<LikedSong> box, _) {
                  final songs = box.values.toList();

                  return Column(
                    children: [
                      _buildHeader(
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        songsCount: songs.length,
                      ),
                      Expanded(
                        child: songs.isEmpty
                            ? _buildEmptyState(
                                customColorsEnabled: customColorsEnabled,
                                primaryColor: primaryColor,
                              )
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 20,
                                  ),
                                  itemCount: songs.length,
                                  itemBuilder: (context, index) {
                                    final song = songs[index];
                                    final isCurrentSong =
                                        playerState.currentSong?['id'] ==
                                            song.id &&
                                        playerState.currentContext == "liked";

                                    return _buildSongCard(
                                      song,
                                      index,
                                      songs,
                                      isCurrentSong,
                                      isCurrentSong && playerState.isPlaying,
                                      isCurrentSong &&
                                          playerState.isSongLoading,
                                      customColorsEnabled,
                                      primaryColor,
                                      secondaryColor,
                                      () => likedSongsBox.delete(song.id),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
