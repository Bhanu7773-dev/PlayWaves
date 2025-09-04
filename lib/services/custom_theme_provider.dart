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
  IconData? _customIcon;

  static const IconData _defaultIcon = Icons.color_lens;
  IconData get customIcon => _customIcon ?? _defaultIcon;

  CustomThemeProvider() {
    loadThemeFromPrefs();
  }

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    customColorsEnabled = prefs.getBool('customColorsEnabled') ?? false;
    primaryColor = Color(prefs.getInt('primaryColor') ?? 0xFFff7d78);
    secondaryColor = Color(prefs.getInt('secondaryColor') ?? 0xFF16213e);
    int? iconCode = prefs.getInt('customIcon');
    _customIcon = iconCode != null
        ? IconData(iconCode, fontFamily: 'MaterialIcons')
        : null;
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
    _customIcon = icon;
    await prefs.setInt('customIcon', icon.codePoint);
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
