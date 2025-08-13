import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/jiosaavn_api_service.dart';
import '../screens/artist_songs_page.dart';
import '../services/custom_theme_provider.dart';

class ArtistSection extends StatelessWidget {
  final List<Map<String, dynamic>> artists;
  final JioSaavnApiService apiService;
  final AudioPlayer audioPlayer;

  const ArtistSection({
    Key? key,
    required this.artists,
    required this.apiService,
    required this.audioPlayer,
  }) : super(key: key);

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
                    "Popular Artists",
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
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ArtistSongsPage(
                            artistName: artist['name'] ?? 'Unknown Artist',
                            apiService: apiService,
                            audioPlayer: audioPlayer,
                          ),
                        ),
                      );
                    },
                    child: _buildArtistCard(
                      artist,
                      customColorsEnabled: customColorsEnabled,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildArtistCard(
    Map<String, dynamic> artist, {
    required bool customColorsEnabled,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: customColorsEnabled
                    ? [
                        primaryColor.withValues(alpha: 0.4),
                        primaryColor.withValues(alpha: 0.2),
                      ]
                    : [
                        const Color(0xFFff7d78).withValues(alpha: 0.3),
                        const Color(0xFF9c27b0).withValues(alpha: 0.3),
                      ],
              ),
              border: customColorsEnabled
                  ? Border.all(
                      color: primaryColor.withValues(alpha: 0.5),
                      width: 2,
                    )
                  : null,
            ),
            child: ClipOval(
              child: _getBestImageUrl(artist['image']) != null
                  ? Image.network(
                      _getBestImageUrl(artist['image'])!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: customColorsEnabled
                              ? primaryColor.withValues(alpha: 0.8)
                              : Colors.white,
                          size: 40,
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      color: customColorsEnabled
                          ? primaryColor.withValues(alpha: 0.8)
                          : Colors.white,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artist['name'] ?? 'Unknown Artist',
            style: TextStyle(
              color: customColorsEnabled
                  ? primaryColor.withValues(alpha: 0.9)
                  : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
