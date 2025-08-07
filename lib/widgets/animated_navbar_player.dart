import 'package:flutter/material.dart';

class AnimatedPlayerNavBar extends StatelessWidget {
  final bool isPlaying;
  final String songTitle;
  final String albumArtUrl;
  final VoidCallback onPlayPause;
  final int selectedIndex;
  final Function(int) onNavTap;
  final List<IconData> navIcons;
  final List<String>? navLabels;
  final VoidCallback? onMiniPlayerTap;

  const AnimatedPlayerNavBar({
    required this.isPlaying,
    required this.songTitle,
    required this.albumArtUrl,
    required this.onPlayPause,
    required this.selectedIndex,
    required this.onNavTap,
    required this.navIcons,
    this.navLabels,
    this.onMiniPlayerTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final labels =
        navLabels ?? ['Home', 'Search', 'Playlist', 'Usage', 'Profile'];
    final icons = navIcons.isNotEmpty
        ? navIcons
        : [
            Icons.home,
            Icons.search,
            Icons.playlist_play,
            Icons.bar_chart,
            Icons.person_outline,
          ];

    final pillCount = icons.length;
    final pillSpacing = 10.0;
    double minUnselectedWidth = 52;

    // Selected pill width, with enough padding for "Profile"
    double selectedLabelWidth = _measureTextWidth(
      labels[selectedIndex],
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
    double selectedWidth = selectedLabelWidth + 28 + 6 + 24;

    // Main nav bar background color (minimal, modern)
    final Color navBarColor = const Color(0xFF23262A);

    // Pills colors
    final Color pillSelectedColor = Colors.white.withOpacity(
      0.08,
    ); // Compliment: subtle light pill
    final Color pillUnselectedColor = navBarColor; // Match nav bar background

    // Icon colors for contrast
    final Color iconSelectedColor = Colors.white;
    final Color iconUnselectedColor = Colors.white.withOpacity(0.7);

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: navBarColor, // lighter than page background
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          height: isPlaying ? 170 : 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPlaying)
                GestureDetector(
                  onTap: onMiniPlayerTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          albumArtUrl,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          songTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 18),
                      GestureDetector(
                        onTap: onPlayPause,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: navBarColor, // match nav bar background
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: iconSelectedColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isPlaying) const SizedBox(height: 18),

              LayoutBuilder(
                builder: (context, constraints) {
                  double availableWidth = constraints.maxWidth;
                  double pillsTotalWidth =
                      selectedWidth +
                      (pillCount - 1) * (minUnselectedWidth + pillSpacing);

                  Widget pillsRow = Row(
                    children: List.generate(pillCount, (i) {
                      final bool selected = i == selectedIndex;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: i < pillCount - 1 ? pillSpacing : 0,
                        ),
                        child: GestureDetector(
                          onTap: () => onNavTap(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: selected
                                ? selectedWidth
                                : minUnselectedWidth,
                            padding: selected
                                ? const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 12,
                                  )
                                : const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 0,
                                  ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? pillSelectedColor
                                  : pillUnselectedColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: selected
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: navBarColor,
                                        ),
                                        width: 28,
                                        height: 28,
                                        child: Icon(
                                          icons[i],
                                          color: iconSelectedColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        labels[i],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: navBarColor,
                                      ),
                                      width: 28,
                                      height: 28,
                                      child: Icon(
                                        icons[i],
                                        color: iconUnselectedColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
                  );

                  if (pillsTotalWidth <= availableWidth) {
                    return pillsRow;
                  } else {
                    // Pills overflow container, use SingleChildScrollView
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(pillCount, (i) {
                          final bool selected = i == selectedIndex;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: i < pillCount - 1 ? pillSpacing : 0,
                            ),
                            child: GestureDetector(
                              onTap: () => onNavTap(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                width: selected
                                    ? selectedWidth
                                    : minUnselectedWidth,
                                padding: selected
                                    ? const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      )
                                    : const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 0,
                                      ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? pillSelectedColor
                                      : pillUnselectedColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: selected
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: navBarColor,
                                            ),
                                            width: 28,
                                            height: 28,
                                            child: Icon(
                                              icons[i],
                                              color: iconSelectedColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            labels[i],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: navBarColor,
                                          ),
                                          width: 28,
                                          height: 28,
                                          child: Icon(
                                            icons[i],
                                            color: iconUnselectedColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Measures text width for sizing pills (uses current font logic)
double _measureTextWidth(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return textPainter.size.width;
}
