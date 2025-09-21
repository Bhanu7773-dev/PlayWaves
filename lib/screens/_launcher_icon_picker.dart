import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/custom_theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> launcherIconNames = [
  'ic_launcher',
  'ic_launcher_1',
  'ic_launcher_2',
  'ic_launcher_3',
];

String getIconAsset(String iconName) {
  return 'assets/image/$iconName.png';
}

class LauncherIconPicker extends StatefulWidget {
  @override
  State<LauncherIconPicker> createState() => _LauncherIconPickerState();
}

class _LauncherIconPickerState extends State<LauncherIconPicker>
    with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('icon_changer');

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSelectedIcon();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSelectedIcon();
    }
  }

  Future<void> _loadSelectedIcon() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('selected_launcher_icon') ?? 0;
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> _saveSelectedIconIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_launcher_icon', index);
  }

  Future<void> _onIconTap(int index) async {
    await _saveSelectedIconIndex(index);

    String? alias;
    if (index == 1)
      alias = "IconAlias1";
    else if (index == 2)
      alias = "IconAlias2";
    else if (index == 3)
      alias = "IconAlias3";

    try {
      await _channel.invokeMethod('changeIcon', {"alias": alias});
    } catch (e) {
      debugPrint('Failed to change icon: $e');
    }

    setState(() {
      selectedIndex = index; // update immediately for ring highlight
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomThemeProvider>(context, listen: false);
    final customColorsEnabled = provider.customColorsEnabled;
    final useDynamicColors = provider.useDynamicColors;
    final primaryColor = provider.primaryColor;
    final scheme = Theme.of(context).colorScheme;

    Color getRingColor(bool isSelected) {
      if (!isSelected) return Colors.white24;
      if (useDynamicColors) return scheme.primary;
      if (customColorsEnabled) return primaryColor;
      return const Color(0xFF6366f1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'App Icon',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: launcherIconNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final iconName = launcherIconNames[index];
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => _onIconTap(index),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: getRingColor(isSelected),
                      width: isSelected ? 3 : 1.2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: getRingColor(isSelected).withOpacity(0.18),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image(
                        image: AssetImage(getIconAsset(iconName)),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.image_not_supported,
                          color: Colors.white24,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
