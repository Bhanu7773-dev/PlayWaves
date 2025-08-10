import 'package:flutter/material.dart';
import '../screens/settings_page.dart';

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
  }

  @override
  void didUpdateWidget(AnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
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
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
        left: 0,
        right: 0,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Color(0x88000000),
            Color(0x44000000),
            Colors.transparent,
          ],
          stops: [0.3, 0.6, 0.9, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(icons.length, (index) {
          final isSelected = index == widget.selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onNavTap(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      transform: Matrix4.identity()
                        ..scale(isSelected ? 1.2 : 1.0),
                      child: ShaderMask(
                        shaderCallback: (bounds) => isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFff7d78), Color(0xFF9c27b0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds)
                            : const LinearGradient(
                                colors: [Colors.white60, Colors.white60],
                              ).createShader(bounds),
                        child: Icon(
                          icons[index],
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
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
    );
  }
}
