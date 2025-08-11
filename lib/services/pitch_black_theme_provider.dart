import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PitchBlackThemeProvider extends ChangeNotifier {
  bool _isPitchBlack = false;

  bool get isPitchBlack => _isPitchBlack;

  PitchBlackThemeProvider() {
    _loadPitchBlackTheme();
  }

  Future<void> _loadPitchBlackTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isPitchBlack = prefs.getBool('pitchBlack') ?? false;
    notifyListeners();
  }

  Future<void> setPitchBlack(bool value) async {
    _isPitchBlack = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pitchBlack', value);
    notifyListeners();
  }
}
