import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../services/custom_theme_provider.dart';
import '../services/player_state_provider.dart';

class RandomSongsSection extends StatefulWidget {
  final List<Map<String, dynamic>> randomSongs;
  final void Function(Map<String, dynamic> song, int index) onSongPlay;
  final String? Function(dynamic images) getBestImageUrl;

  const RandomSongsSection({
    Key? key,
    required this.randomSongs,
    required this.onSongPlay,
    required this.getBestImageUrl,
  }) : super(key: key);

  @override
  State<RandomSongsSection> createState() => _RandomSongsSectionState();
}

class _RandomSongsSectionState extends State<RandomSongsSection> {
  late List<SwipeItem> _swipeItems;
  late MatchEngine _matchEngine;

  @override
  void initState() {
    super.initState();
    _initSwipeEngine();
  }

  void _initSwipeEngine() {
    _swipeItems = [];
    for (var i = 0; i < widget.randomSongs.length; i++) {
      final song = widget.randomSongs[i];
      _swipeItems.add(
        SwipeItem(
          content: song,
          likeAction: () {},
          nopeAction: () {},
          superlikeAction: () {},
        ),
      );
    }
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  @override
  void didUpdateWidget(covariant RandomSongsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.randomSongs != widget.randomSongs) {
      _initSwipeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.randomSongs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            "No random songs available",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Consumer<CustomThemeProvider>(
      builder: (context, customTheme, child) {
        final customColorsEnabled = customTheme.customColorsEnabled;
        final useDynamicColors = customTheme.useDynamicColors;
        final primaryColor = customTheme.primaryColor;
        final secondaryColor = customTheme.secondaryColor;
        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: useDynamicColors
                          ? LinearGradient(
                              colors: [
                                scheme.primary,
                                scheme.primary.withOpacity(0.7),
                              ],
                            )
                          : customColorsEnabled
                          ? LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.7),
                              ],
                            )
                          : LinearGradient(
                              colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Random Picks",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 360,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return SwipeCards(
                    matchEngine: _matchEngine,
                    itemBuilder: (context, index) {
                      return _buildSongCard(
                        context,
                        widget.randomSongs[index],
                        index,
                        customColorsEnabled: customColorsEnabled,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        useDynamicColors: useDynamicColors,
                        scheme: scheme,
                      );
                    },
                    onStackFinished: () {
                      Future.delayed(const Duration(milliseconds: 400), () {
                        setState(() {
                          _swipeItems.clear();
                          for (var i = 0; i < widget.randomSongs.length; i++) {
                            final song = widget.randomSongs[i];
                            _swipeItems.add(
                              SwipeItem(
                                content: song,
                                likeAction: () {},
                                nopeAction: () {},
                                superlikeAction: () {},
                              ),
                            );
                          }
                          _matchEngine = MatchEngine(swipeItems: _swipeItems);
                        });
                      });
                    },
                    upSwipeAllowed: false,
                    fillSpace: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongCard(
    BuildContext context,
    Map<String, dynamic> song,
    int index, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
    required bool useDynamicColors,
    required ColorScheme scheme,
  }) {
    final imageUrl = widget.getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    final artist =
        song['artists']?['primary']?[0]?['name'] ??
        song['subtitle'] ??
        'Unknown Artist';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: useDynamicColors
          ? scheme.surface.withOpacity(0.8)
          : customColorsEnabled
          ? secondaryColor.withOpacity(0.8)
          : const Color.fromARGB(255, 17, 17, 17),
      child: Stack(
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: customColorsEnabled
                                  ? [
                                      primaryColor.withOpacity(0.3),
                                      primaryColor.withOpacity(0.1),
                                    ]
                                  : [Colors.grey[800]!, Colors.grey[700]!],
                            ),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: customColorsEnabled
                                ? primaryColor.withOpacity(0.7)
                                : Colors.white54,
                            size: 48,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: customColorsEnabled
                                ? [
                                    primaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.1),
                                  ]
                                : [Colors.grey[800]!, Colors.grey[700]!],
                          ),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: customColorsEnabled
                              ? primaryColor.withOpacity(0.7)
                              : Colors.white54,
                          size: 48,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: customColorsEnabled
                            ? primaryColor.withOpacity(0.9)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      artist,
                      style: TextStyle(
                        color: customColorsEnabled
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Consumer<PlayerStateProvider>(
                  builder: (context, playerState, child) {
                    final audioPlayer = Provider.of<AudioPlayer>(
                      context,
                      listen: false,
                    );
                    final isCurrentSong =
                        playerState.currentSong != null &&
                        playerState.currentSong!['id'] == song['id'];
                    final isPlaying = playerState.isPlaying && isCurrentSong;
                    final isLoading =
                        playerState.isSongLoading && isCurrentSong;

                    return CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.transparent,
                      child: IconButton(
                        icon: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: useDynamicColors
                                      ? LinearGradient(
                                          colors: [
                                            scheme.primary,
                                            scheme.primary.withOpacity(0.8),
                                          ],
                                        )
                                      : customColorsEnabled
                                      ? LinearGradient(
                                          colors: [
                                            primaryColor,
                                            primaryColor.withOpacity(0.8),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Color(0xFF6366f1),
                                            Color(0xFF8b5cf6),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final playerState =
                                    Provider.of<PlayerStateProvider>(
                                      context,
                                      listen: false,
                                    );

                                try {
                                  if (isCurrentSong && isPlaying) {
                                    await audioPlayer.pause();
                                    playerState.setPlaying(false);
                                  } else if (isCurrentSong && !isPlaying) {
                                    await audioPlayer.play();
                                    playerState.setPlaying(true);
                                  } else {
                                    widget.onSongPlay(song, index);
                                  }
                                } catch (e) {
                                  print('Error in random songs play/pause: $e');
                                  final actuallyPlaying = audioPlayer.playing;
                                  playerState.setPlaying(actuallyPlaying);
                                }
                              },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: useDynamicColors
                    ? scheme.primary.withOpacity(0.8)
                    : customColorsEnabled
                    ? primaryColor.withOpacity(0.8)
                    : Colors.deepPurple.withOpacity(0.84),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  SizedBox(width: 5),
                  Text(
                    "Swipe to see magic!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
}
