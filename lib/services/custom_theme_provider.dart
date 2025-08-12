import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomThemeProvider with ChangeNotifier {
  // Load theme settings from SharedPreferences
  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    customColorsEnabled = prefs.getBool('customColorsEnabled') ?? false;
    primaryColor = Color(prefs.getInt('primaryColor') ?? 0xFFff7d78);
    secondaryColor = Color(prefs.getInt('secondaryColor') ?? 0xFF16213e);
    print(
      '[CustomThemeProvider] Loaded from prefs: customColorsEnabled=$customColorsEnabled, primaryColor=$primaryColor, secondaryColor=$secondaryColor',
    );
    notifyListeners();
  }

  bool customColorsEnabled;
  Color primaryColor;
  Color secondaryColor;

  CustomThemeProvider({
    this.customColorsEnabled = false,
    this.primaryColor = const Color(0xFFff7d78),
    this.secondaryColor = const Color(0xFF16213e),
  }) {
    // Load persisted theme on provider initialization
    loadThemeFromPrefs();
  }

  void setCustomColorsEnabled(bool value) {
    customColorsEnabled = value;
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    primaryColor = color;
    print('[CustomThemeProvider] primaryColor set to: ' + color.toString());
    notifyListeners();
  }

  void setSecondaryColor(Color color) {
    secondaryColor = color;
    print('[CustomThemeProvider] secondaryColor set to: ' + color.toString());
    notifyListeners();
  }

  void updateTheme({
    required bool enabled,
    required Color primary,
    required Color secondary,
  }) {
    customColorsEnabled = enabled;
    primaryColor = primary;
    secondaryColor = secondary;
    notifyListeners();
  }
}
