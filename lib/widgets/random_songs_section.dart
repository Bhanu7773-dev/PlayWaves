import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';

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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
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
                  final song = widget.randomSongs[index];
                  final imageUrl = widget.getBestImageUrl(song['image']);
                  final title = song['name'] ?? song['title'] ?? 'Unknown Song';
                  final artist =
                      song['artists']?['primary']?[0]?['name'] ??
                      song['subtitle'] ??
                      'Unknown Artist';
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: const Color.fromARGB(
                      255,
                      17,
                      17,
                      17,
                    ).withOpacity(1.0),
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
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white54,
                                          size: 48,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: 180,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white54,
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    artist,
                                    style: const TextStyle(
                                      color: Colors.white70,
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
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFff7d78),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      widget.onSongPlay(song, index),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.84),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 16,
                                ),
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
  }
}
