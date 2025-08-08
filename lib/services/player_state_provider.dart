import 'package:flutter/material.dart';

class PlayerStateProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentSong;
  List<Map<String, dynamic>> _currentPlaylist = [];
  int _currentSongIndex = 0;
  bool _isPlaying = false;
  bool _isSongLoading = false;

  Map<String, dynamic>? get currentSong => _currentSong;
  List<Map<String, dynamic>> get currentPlaylist => _currentPlaylist;
  int get currentSongIndex => _currentSongIndex;
  bool get isPlaying => _isPlaying;
  bool get isSongLoading => _isSongLoading;

  void setSong(Map<String, dynamic>? song) {
    _currentSong = song;
    notifyListeners();
  }

  void setPlaylist(List<Map<String, dynamic>> playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  void setSongIndex(int index) {
    _currentSongIndex = index;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setSongLoading(bool loading) {
    _isSongLoading = loading;
    notifyListeners();
  }

  void clearSong() {
    _currentSong = null;
    _isPlaying = false;
    _isSongLoading = false;
    _currentPlaylist = [];
    _currentSongIndex = 0;
    notifyListeners();
  }
}
