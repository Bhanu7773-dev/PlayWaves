import 'package:flutter/material.dart';

// Make sure you have 'clarity_icons' in your pubspec.yaml and run 'flutter pub get'
// dependencies:
//   clarity_icons: ^1.1.2

import 'package:icons_plus/icons_plus.dart';

class HomePage extends StatelessWidget {
  final String username;
  const HomePage({super.key, this.username = "User Name"});

  @override
  Widget build(BuildContext context) {
    final List<_FeatureCardData> featureCards = [
      _FeatureCardData(
        title: "Most played",
        icon: Clarity.play_line, // Clarity play icon
        color: Colors.orangeAccent,
      ),
      _FeatureCardData(
        title: "History",
        icon: Clarity.history_line, // Clarity history icon
        color: Colors.grey[400]!,
      ),
      _FeatureCardData(
        title: "Favourite",
        icon: Clarity.favorite_line, // Clarity heart icon
        color: Colors.pinkAccent,
      ),
      _FeatureCardData(
        title: "Playlists",
        icon: Clarity.folder_line, // Clarity folder/playlist icon
        color: Colors.blueAccent,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Clarity.search_line, color: Colors.white),
          onPressed: () {},
        ),
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Play',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              TextSpan(
                text: 'Waves',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Clarity.devices_line, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Clarity.settings_line, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // Avatar + Welcome Section
          Padding(
            padding: const EdgeInsets.only(left: 22.0, top: 18.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: Colors.blueAccent,
                  size: 45,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome,",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Feature cards grid (2x2) with new order and names
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 14.0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _FeatureCard(data: featureCards[0])),
                    const SizedBox(width: 12),
                    Expanded(child: _FeatureCard(data: featureCards[1])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _FeatureCard(data: featureCards[2])),
                    const SizedBox(width: 12),
                    Expanded(child: _FeatureCard(data: featureCards[3])),
                  ],
                ),
              ],
            ),
          ),
          // Suggestions title and refresh button row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                const Text(
                  "Suggestions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Clarity.refresh_line,
                    color: Colors.white,
                    size: 25,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // --- Custom Suggestions Grid with increased sizes ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: CustomSuggestionsGrid(),
          ),
          // Top Artists label (optional, for further content)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: const Text(
              "Top artists",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Feature Card Data and Widget ----

class _FeatureCardData {
  final String title;
  final IconData icon;
  final Color color;
  _FeatureCardData({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureCardData data;
  const _FeatureCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(data.icon, color: data.color, size: 22),
            const SizedBox(width: 10),
            Text(
              data.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Custom Suggestions Layout as Per Your Image ----

class CustomSuggestionsGrid extends StatelessWidget {
  const CustomSuggestionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Get available width (with horizontal padding 18)
    final double panelWidth = MediaQuery.of(context).size.width - 2 * 18;

    // Calculate sizing dynamically so all boxes fill width (plus gaps)
    // 4 columns: [big (2x2)] [small] [rectW (2x1)] [circle]
    // Let's set gap = 12, and sum all sizes + 4*gap = panelWidth
    // Let x = base box size; then big = 2x + gap, small = x, rectW = 2x + gap, circle = 1.1x
    // So: (2x+gap) + gap + x + gap + (2x+gap) + gap + 1.1x = panelWidth
    // Simplify: 2x+gap + gap + x + gap + 2x+gap + gap +1.1x = panelWidth
    // => (2x+gap) + gap + x + gap + 2x+gap + gap + 1.1x
    // => 2x + gap + gap + x + gap + 2x + gap + gap + 1.1x
    // => (2x + x + 2x + 1.1x) + (gap + gap + gap + gap)
    // => (5.1x) + (4*gap)
    // => 5.1x + 4*gap = panelWidth
    // => x = (panelWidth - 4*gap)/5.1

    const double gap = 12;
    final double x = (panelWidth - 4 * gap) / 5.1;
    final double small = x;
    final double big = 2 * x + gap;
    final double rectW = 2 * x + gap;
    final double rectH = x;
    final double circle = 1.1 * x;

    return SizedBox(
      width: panelWidth,
      height: big + gap + small + gap + rectH + gap + circle,
      child: Stack(
        children: [
          // Large 2x2 square (top left)
          Positioned(
            left: 0,
            top: 0,
            width: big,
            height: big,
            child: _SuggestionCover(
              borderRadius: BorderRadius.circular(18),
              gradient: [Colors.blueGrey[900]!, Colors.blue[800]!],
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  "New\nMusic\nMix",
                  style: TextStyle(
                    color: Colors.lightBlue[100],
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
          // Top right small square
          Positioned(
            left: big + gap,
            top: 0,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Top right rectangle (2x1)
          Positioned(
            left: big + gap + small + gap,
            top: 0,
            width: rectW,
            height: rectH,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          // Middle row, first two small squares
          Positioned(
            left: big + gap,
            top: small + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: big + gap + small + gap,
            top: small + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Small square below previous rectangle
          Positioned(
            left: big + gap + 2 * (small + gap),
            top: rectH + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Bottom left two small squares
          Positioned(
            left: 0,
            top: big + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            left: small + gap,
            top: big + gap,
            width: small,
            height: small,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Bottom rectangle (2x1)
          Positioned(
            left: 2 * (small + gap),
            top: big + gap,
            width: rectW,
            height: rectH,
            child: _SuggestionCover(
              image:
                  "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          // Circle, to the right of the 3rd row rectangle (aligned with it vertically)
          Positioned(
            left: 2 * (small + gap) + rectW + gap,
            top: big + gap + (rectH / 2) - (circle / 2),
            width: circle,
            height: circle,
            child: _SuggestionCover(
              isCircle: true,
              image:
                  "https://images.unsplash.com/photo-1465101178521-c1a9136a03d4?auto=format&fit=crop&w=400&q=80",
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCover extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;
  final List<Color>? gradient;
  final String? image;
  final bool isCircle;
  final BorderRadius? borderRadius;

  const _SuggestionCover({
    this.width,
    this.height,
    this.child,
    this.gradient,
    this.image,
    this.isCircle = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = image != null && image!.isNotEmpty;
    final bool hasGradient = gradient != null && gradient!.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : (borderRadius ?? BorderRadius.circular(13)),
        gradient: hasGradient
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: hasImage
            ? DecorationImage(image: NetworkImage(image!), fit: BoxFit.cover)
            : null,
      ),
      child: child,
    );
  }
}
