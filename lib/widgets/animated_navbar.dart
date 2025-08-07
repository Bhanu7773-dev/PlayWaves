import 'package:flutter/material.dart';

class AnimatedNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onNavTap;
  final List<IconData> navIcons;
  final List<String>? navLabels;

  const AnimatedNavBar({
    required this.selectedIndex,
    required this.onNavTap,
    required this.navIcons,
    this.navLabels,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    _previousIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(AnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _slideController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels =
        widget.navLabels ?? ['Home', 'Search', 'Playlist', 'Profile'];
    final icons = widget.navIcons.isNotEmpty
        ? widget.navIcons
        : [Icons.home, Icons.search, Icons.playlist_play, Icons.person_outline];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f0f23)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFff7d78).withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding gradient background
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final screenWidth = MediaQuery.of(context).size.width;
              final containerWidth = screenWidth - 32; // Account for margin
              final itemWidth = containerWidth / icons.length;
              final startPosition = _previousIndex * itemWidth;
              final endPosition = widget.selectedIndex * itemWidth;
              final currentPosition =
                  startPosition +
                  (endPosition - startPosition) * _slideAnimation.value;

              return Positioned(
                left: currentPosition + 16,
                top: 6,
                child: Container(
                  width: itemWidth - 32,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFff7d78).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Nav items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(icons.length, (index) {
              final isSelected = index == widget.selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onNavTap(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          transform: Matrix4.identity()
                            ..scale(isSelected ? 1.2 : 1.0),
                          child: Icon(
                            icons[index],
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                            fontSize: isSelected ? 12 : 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          child: Text(labels[index]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
