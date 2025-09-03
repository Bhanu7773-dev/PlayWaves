import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../services/custom_theme_provider.dart';

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
                      gradient: customColorsEnabled
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
                return _buildMasonrySongCard(
                  song,
                  index,
                  context,
                  customColorsEnabled: customColorsEnabled,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMasonrySongCard(
    Map<String, dynamic> song,
    int index,
    BuildContext context, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
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
          color: customColorsEnabled
              ? primaryColor.withValues(alpha: 0.05)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: customColorsEnabled
                ? primaryColor.withValues(alpha: 0.2)
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: customColorsEnabled
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
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
                    if (customColorsEnabled)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              primaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                  ],
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
                    style: TextStyle(
                      color: customColorsEnabled
                          ? primaryColor.withValues(alpha: 0.9)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
