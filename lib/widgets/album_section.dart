import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../services/custom_theme_provider.dart';
import '../services/player_state_provider.dart';

class AlbumsSection extends StatelessWidget {
  final List<Map<String, dynamic>> albums;
  final void Function(Map<String, dynamic> album) onAlbumPlay;
  final String? Function(dynamic images) getBestImageUrl;
  final AudioPlayer audioPlayer;

  const AlbumsSection({
    Key? key,
    required this.albums,
    required this.onAlbumPlay,
    required this.getBestImageUrl,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SizedBox.shrink();
    }
    return Consumer<CustomThemeProvider>(
      builder: (context, customTheme, child) {
        final customColorsEnabled = customTheme.customColorsEnabled;
        final primaryColor = customTheme.primaryColor;
        final secondaryColor = customTheme.secondaryColor;

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
                      gradient: LinearGradient(
                        colors: customColorsEnabled
                            ? [
                                primaryColor,
                                primaryColor.withValues(alpha: 0.7),
                              ]
                            : [Color(0xFFff7d78), Color(0xFF9c27b0)],
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
                  return _buildAlbumCard(
                    album,
                    customColorsEnabled: customColorsEnabled,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumCard(
    Map<String, dynamic> album, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
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
          colors: customColorsEnabled
              ? [
                  secondaryColor.withValues(alpha: 0.2),
                  secondaryColor.withValues(alpha: 0.1),
                ]
              : [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
        ),
        border: Border.all(
          color: customColorsEnabled
              ? primaryColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
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
                                colors: customColorsEnabled
                                    ? [
                                        primaryColor.withValues(alpha: 0.3),
                                        primaryColor.withValues(alpha: 0.1),
                                      ]
                                    : [
                                        const Color(
                                          0xFFff7d78,
                                        ).withValues(alpha: 0.3),
                                        const Color(
                                          0xFF9c27b0,
                                        ).withValues(alpha: 0.3),
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
                            colors: customColorsEnabled
                                ? [
                                    primaryColor.withValues(alpha: 0.3),
                                    primaryColor.withValues(alpha: 0.1),
                                  ]
                                : [
                                    const Color(
                                      0xFFff7d78,
                                    ).withValues(alpha: 0.3),
                                    const Color(
                                      0xFF9c27b0,
                                    ).withValues(alpha: 0.3),
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
                gradient: LinearGradient(
                  colors: customColorsEnabled
                      ? [primaryColor, primaryColor.withValues(alpha: 0.8)]
                      : [Color(0xFFff7d78), Color(0xFF9c27b0)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: customColorsEnabled
                        ? primaryColor.withValues(alpha: 0.3)
                        : const Color(0xFFff7d78).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Consumer<PlayerStateProvider>(
                builder: (context, playerState, child) {
                  // Check if any song from this album is currently playing
                  // Since albums don't have direct song lists, we'll check if the current song's album matches
                  final currentSong = playerState.currentSong;
                  bool isCurrentAlbum = false;

                  if (currentSong != null) {
                    // Try to match by album ID if available
                    final currentAlbumId =
                        currentSong['album']?['id'] ?? currentSong['albumId'];
                    final thisAlbumId = album['id'];
                    isCurrentAlbum =
                        currentAlbumId != null && currentAlbumId == thisAlbumId;

                    // If no album ID match, try matching by album name
                    if (!isCurrentAlbum) {
                      final currentAlbumName =
                          currentSong['album']?['name'] ??
                          currentSong['albumName'];
                      final thisAlbumName = album['name'] ?? album['title'];
                      isCurrentAlbum =
                          currentAlbumName != null &&
                          thisAlbumName != null &&
                          currentAlbumName == thisAlbumName;
                    }
                  }

                  final isPlaying = playerState.isPlaying && isCurrentAlbum;
                  final isLoading = playerState.isSongLoading && isCurrentAlbum;

                  return IconButton(
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
                        : Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final playerState =
                                Provider.of<PlayerStateProvider>(
                                  context,
                                  listen: false,
                                );

                            if (isCurrentAlbum && isPlaying) {
                              // Pause current album/song
                              playerState.setPlaying(false);
                              await Future.delayed(Duration(milliseconds: 50));
                              try {
                                await audioPlayer.pause();
                              } catch (e) {
                                playerState.setPlaying(true);
                              }
                            } else if (isCurrentAlbum && !isPlaying) {
                              // Resume current album/song
                              playerState.setPlaying(true);
                              await Future.delayed(Duration(milliseconds: 50));
                              try {
                                await audioPlayer.play();
                              } catch (e) {
                                playerState.setPlaying(false);
                              }
                            } else {
                              // Play a different album
                              onAlbumPlay(album);
                            }
                          },
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
