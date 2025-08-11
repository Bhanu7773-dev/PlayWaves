import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MasonrySongSection extends StatelessWidget {
  final List<Map<String, dynamic>> songs;
  final Function(Map<String, dynamic> song, int index) onSongTap;
  final String? Function(dynamic images) getBestImageUrl;

  const MasonrySongSection({
    Key? key,
    required this.songs,
    required this.onSongTap,
    required this.getBestImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                "Trending Songs",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return _buildMasonrySongCard(song, index, context);
          },
        ),
      ],
    );
  }

  Widget _buildMasonrySongCard(
    Map<String, dynamic> song,
    int index,
    BuildContext context,
  ) {
    final imageUrl = getBestImageUrl(song['image']);
    final title = song['name'] ?? song['title'] ?? 'Unknown Song';
    String artist = 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        artist = artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['subtitle'] != null) {
      artist = song['subtitle'];
    }

    return GestureDetector(
      onTap: () => onSongTap(song, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
