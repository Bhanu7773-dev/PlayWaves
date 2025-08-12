import 'package:flutter/material.dart';

class CustomThemeProvider with ChangeNotifier {
  bool customColorsEnabled;
  Color primaryColor;
  Color secondaryColor;

  CustomThemeProvider({
    this.customColorsEnabled = false,
    this.primaryColor = const Color(0xFFff7d78),
    this.secondaryColor = const Color(0xFF16213e),
  });

  void setCustomColorsEnabled(bool value) {
    customColorsEnabled = value;
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    primaryColor = color;
    notifyListeners();
  }

  void setSecondaryColor(Color color) {
    secondaryColor = color;
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
