import 'package:flutter/material.dart';

class AlbumsSection extends StatelessWidget {
  final List<Map<String, dynamic>> albums;
  final void Function(Map<String, dynamic> album) onAlbumPlay;
  final String? Function(dynamic images) getBestImageUrl;

  const AlbumsSection({
    Key? key,
    required this.albums,
    required this.onAlbumPlay,
    required this.getBestImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SizedBox.shrink();
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
                "Featured Albums",
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
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return _buildAlbumCard(album);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    final imageUrl = getBestImageUrl(album['image']);
    final title = album['name'] ?? album['title'] ?? 'Unknown Album';
    final subtitle = album['subtitle'] ?? album['artist'] ?? 'Unknown Artist';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
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
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFff7d78).withOpacity(0.3),
                                  const Color(0xFF9c27b0).withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.album,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 160,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFff7d78).withOpacity(0.3),
                              const Color(0xFF9c27b0).withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.album,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFff7d78).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => onAlbumPlay(album),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
