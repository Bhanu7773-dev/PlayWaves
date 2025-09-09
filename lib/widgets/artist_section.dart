import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/jiosaavn_api_service.dart';
import '../screens/artist_songs_page.dart';
import '../services/custom_theme_provider.dart';

class ArtistSection extends StatefulWidget {
  final List<Map<String, dynamic>> artists;
  final JioSaavnApiService apiService;
  final AudioPlayer audioPlayer;

  const ArtistSection({
    Key? key,
    required this.artists,
    required this.apiService,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  State<ArtistSection> createState() => _ArtistSectionState();
}

class _ArtistSectionState extends State<ArtistSection>
    with TickerProviderStateMixin {
  late Map<String, bool> _likedArtists;
  late Map<String, AnimationController> _likeAnimationControllers;
  late Map<String, Animation<double>> _likeAnimations;

  @override
  void initState() {
    super.initState();
    _likedArtists = {};
    _likeAnimationControllers = {};
    _likeAnimations = {};

    // Initialize liked state and animations for each artist
    for (var artist in widget.artists) {
      final artistId = artist['id']?.toString() ?? artist['name']?.toString() ?? '';
      _likedArtists[artistId] = false;

      _likeAnimationControllers[artistId] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );

      _likeAnimations[artistId] = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: _likeAnimationControllers[artistId]!,
        curve: Curves.elasticOut,
      ));
    }
  }

  @override
  void dispose() {
    for (var controller in _likeAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleLike(String artistId) {
    setState(() {
      _likedArtists[artistId] = !(_likedArtists[artistId] ?? false);
    });

    if (_likedArtists[artistId] == true) {
      _likeAnimationControllers[artistId]?.forward().then((_) {
        _likeAnimationControllers[artistId]?.reverse();
      });
    }
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
                itemCount: widget.artists.length,
                itemBuilder: (context, index) {
                  final artist = widget.artists[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ArtistSongsPage(
                            artistName: artist['name'] ?? 'Unknown Artist',
                            apiService: widget.apiService,
                          ),
                        ),
                      );
                    },
                    child: _buildArtistCard(
                      artist,
                      customColorsEnabled: customColorsEnabled,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      useDynamicColors: useDynamicColors,
                      scheme: scheme,
                      onLikeToggle: _toggleLike,
                      isLiked: _likedArtists[artist['id']?.toString() ?? artist['name']?.toString() ?? ''] ?? false,
                      likeAnimation: _likeAnimations[artist['id']?.toString() ?? artist['name']?.toString() ?? ''] ?? AlwaysStoppedAnimation(1.0),
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
    required bool useDynamicColors,
    required ColorScheme scheme,
    required Function(String) onLikeToggle,
    required bool isLiked,
    required Animation<double> likeAnimation,
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
                colors: useDynamicColors
                    ? [
                        scheme.surface.withOpacity(0.4),
                        scheme.surface.withOpacity(0.2),
                      ]
                    : customColorsEnabled
                    ? [
                        primaryColor.withValues(alpha: 0.4),
                        primaryColor.withValues(alpha: 0.2),
                      ]
                    : [
                        const Color(0xFFff7d78).withValues(alpha: 0.3),
                        const Color(0xFF9c27b0).withValues(alpha: 0.3),
                      ],
              ),
              border: useDynamicColors
                  ? Border.all(color: scheme.outline.withOpacity(0.5), width: 2)
                  : customColorsEnabled
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
                          color: useDynamicColors
                              ? scheme.onSurface.withOpacity(0.8)
                              : customColorsEnabled
                              ? primaryColor.withValues(alpha: 0.8)
                              : Colors.white,
                          size: 40,
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      color: useDynamicColors
                          ? scheme.onSurface.withOpacity(0.8)
                          : customColorsEnabled
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
              foreground: useDynamicColors
                  ? (Paint()..color = scheme.onSurface)
                  : customColorsEnabled
                  ? (Paint()..color = Colors.white)
                  : (Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(Rect.fromLTWH(0, 0, 100, 20))),
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
