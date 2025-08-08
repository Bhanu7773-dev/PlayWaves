import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MiniPlayer extends StatelessWidget {
  final Map<String, dynamic>? currentSong;
  final AudioPlayer audioPlayer;
  final bool isSongLoading;
  final VoidCallback? onPlayPause;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    required this.currentSong,
    required this.audioPlayer,
    this.isSongLoading = false,
    this.onPlayPause,
    this.onClose,
    this.onTap,
  });

  String _getArtistName(Map<String, dynamic>? song) {
    if (song == null) return 'Unknown Artist';
    if (song['artists'] != null) {
      final artists = song['artists'];
      if (artists['primary'] != null && artists['primary'].isNotEmpty) {
        return artists['primary'][0]['name'] ?? 'Unknown Artist';
      }
    } else if (song['primaryArtists'] != null) {
      return song['primaryArtists'];
    } else if (song['subtitle'] != null) {
      return song['subtitle'];
    }
    return 'Unknown Artist';
  }

  String? _getBestImageUrl(dynamic images) {
    if (images is List && images.isNotEmpty) {
      for (var img in images.reversed) {
        if (img is Map && img['link'] != null) {
          return img['link'];
        }
        if (img is Map && img['url'] != null) {
          return img['url'];
        }
      }
    } else if (images is String) {
      return images;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (currentSong == null) return const SizedBox.shrink();

    String artistName = _getArtistName(currentSong);
    String albumArtUrl = '';
    if (currentSong?['image'] != null) {
      albumArtUrl = _getBestImageUrl(currentSong!['image']) ?? '';
    }
    final songTitle =
        currentSong?['name'] ?? currentSong?['title'] ?? 'Unknown';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 21, 21, 21).withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Album Art with Hero Animation
              Hero(
                tag: 'album_art_${currentSong?['id'] ?? 'current'}',
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          19,
                          19,
                          19,
                        ).withOpacity(1.0),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: albumArtUrl.isNotEmpty
                        ? Image.network(
                            albumArtUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Song Info with Hero Animation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'song_title_${currentSong?['id'] ?? 'current'}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          songTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Hero(
                      tag: 'artist_name_${currentSong?['id'] ?? 'current'}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          artistName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Control buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/Pause button
                  StreamBuilder<bool>(
                    stream: audioPlayer.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return IconButton(
                        onPressed: onPlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: const Color(0xFFff7d78),
                          size: 28,
                        ),
                        padding: const EdgeInsets.all(4),
                      );
                    },
                  ),
                  // Close button
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
