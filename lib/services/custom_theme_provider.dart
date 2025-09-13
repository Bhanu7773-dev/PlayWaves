import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  bool useDynamicColors = false;
  bool customColorsEnabled = false;
  Color primaryColor = const Color(0xFFff7d78);
  Color secondaryColor = const Color(0xFF16213e);
  String? _customIconName;

  // Predefined icons that can be selected (all constant)
  static const Map<String, IconData> _availableIcons = {
    'color_lens': Icons.color_lens,
    'palette': Icons.palette,
    'brush': Icons.brush,
    'format_paint': Icons.format_paint,
    'colorize': Icons.colorize,
    'gradient': Icons.gradient,
    'style': Icons.style,
    'wallpaper': Icons.wallpaper,
  };

  static const IconData _defaultIcon = Icons.color_lens;
  IconData get customIcon {
    if (_customIconName != null &&
        _availableIcons.containsKey(_customIconName)) {
      return _availableIcons[_customIconName]!;
    }
    return _defaultIcon;
  }

  // Get list of available icons for UI selection
  List<IconData> get availableIcons => _availableIcons.values.toList();
  List<String> get availableIconNames => _availableIcons.keys.toList();

  CustomThemeProvider() {
    loadThemeFromPrefs();
  }

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    customColorsEnabled = prefs.getBool('customColorsEnabled') ?? false;
    useDynamicColors = prefs.getBool('useDynamicColors') ?? false;
    primaryColor = Color(prefs.getInt('primaryColor') ?? 0xFFff7d78);
    secondaryColor = Color(prefs.getInt('secondaryColor') ?? 0xFF16213e);
    _customIconName = prefs.getString('customIconName');
    notifyListeners();
  }

  void setUseDynamicColors(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    useDynamicColors = value;
    await prefs.setBool('useDynamicColors', value);
    notifyListeners();
  }

  void setCustomColorsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    customColorsEnabled = value;
    await prefs.setBool('customColorsEnabled', value);
    notifyListeners();
  }

  void setCustomIcon(IconData icon) async {
    final prefs = await SharedPreferences.getInstance();
    // Find the icon name from the available icons
    String? iconName;
    _availableIcons.forEach((key, value) {
      if (value.codePoint == icon.codePoint) {
        iconName = key;
      }
    });
    _customIconName = iconName;
    if (iconName != null) {
      await prefs.setString('customIconName', iconName!);
    }
    notifyListeners();
  }

  void setPrimaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    primaryColor = color;
    await prefs.setInt('primaryColor', color.value);
    notifyListeners();
  }

  void setSecondaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    secondaryColor = color;
    await prefs.setInt('secondaryColor', color.value);
    notifyListeners();
  }

  void updateTheme({
    required bool enabled,
    required Color primary,
    required Color secondary,
    IconData? icon,
  }) {
    setCustomColorsEnabled(enabled);
    setPrimaryColor(primary);
    setSecondaryColor(secondary);
    if (icon != null) {
      setCustomIcon(icon);
    }
    // No need to call notifyListeners() here, setters already do it.
  }
}
