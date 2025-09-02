import 'package:flutter/material.dart';

class PlayerStateProvider extends ChangeNotifier {
  void clearRecentlyPlayed() {
    _recentlyPlayed.clear();
    notifyListeners();
  }
  Map<String, dynamic>? _currentSong;
  List<Map<String, dynamic>> _currentPlaylist = [];
  // Recently played songs (max 15)
  final List<Map<String, dynamic>> _recentlyPlayed = [];
  int _currentSongIndex = 0;
  bool _isPlaying = false;
  bool _isSongLoading = false;

  // Audio/Download quality for streaming and downloads
  // Defaults to 'High (320 kbps)'
  String? _audioQuality = 'High (320 kbps)';
  String? _downloadQuality = 'High (320 kbps)';

  // Add playback context tracking
  String? _currentContext;
  String? get currentContext => _currentContext;
  void setCurrentContext(String? value) {
    _currentContext = value;
    notifyListeners();
  }

  Map<String, dynamic>? get currentSong => _currentSong;
  List<Map<String, dynamic>> get currentPlaylist => _currentPlaylist;
  int get currentSongIndex => _currentSongIndex;
  bool get isPlaying => _isPlaying;
  bool get isSongLoading => _isSongLoading;

  String? get audioQuality => _audioQuality;
  String? get downloadQuality => _downloadQuality;

  List<Map<String, dynamic>> get recentlyPlayed =>
      List.unmodifiable(_recentlyPlayed);

  void setSong(Map<String, dynamic>? song) {
    // Debug print: show all downloadUrl qualities for each song in recently played
    if (_recentlyPlayed.isNotEmpty) {
      for (var s in _recentlyPlayed) {
        var urlField = s['downloadUrl'];
        if (urlField is List) {
          debugPrint(
            'Song: ${s['name'] ?? s['title'] ?? s['id']} has ${urlField.length} download URLs:',
          );
          for (int i = 0; i < urlField.length; i++) {
            var item = urlField[i];
            if (item is Map && item.containsKey('quality')) {
              debugPrint(
                '  [${i}] quality: ${item['quality']}, url: ${item['url']}',
              );
            } else if (item is String) {
              debugPrint('  [${i}] url: $item');
            }
          }
        } else if (urlField is String) {
          debugPrint(
            'Song: ${s['name'] ?? s['title'] ?? s['id']} has single downloadUrl: $urlField',
          );
        }
      }
    }
    // Add to recently played and debug print
    if (song != null) {
      // Store all available quality download URLs from API
      dynamic urlField = song['downloadUrl'];
      List<Map<String, dynamic>> allQualities = [];
      if (urlField is List && urlField.isNotEmpty) {
        for (var item in urlField) {
          if (item is Map && item['quality'] != null && item['url'] != null) {
            allQualities.add({'quality': item['quality'], 'url': item['url']});
          }
        }
      } else if (urlField is String && urlField.isNotEmpty) {
        allQualities.add({'quality': 'unknown', 'url': urlField});
      }
      song['allDownloadUrls'] = allQualities;
      // Add to recently played (max 15)
      if (song['id'] != null) {
        // Only add to top if not already in the list (i.e., played from outside)
        final idx = _recentlyPlayed.indexWhere((s) => s['id'] == song['id']);
        if (idx == -1) {
          _recentlyPlayed.insert(0, song);
          while (_recentlyPlayed.length > 15) {
            _recentlyPlayed.removeLast();
          }
        }
        // If played from the list, do not reorder
      }
      Future.delayed(Duration(milliseconds: 100), () {
        debugPrint('Recently played songs: ${_recentlyPlayed.length}');
        for (var s in _recentlyPlayed) {
          debugPrint('Song: ${s['name'] ?? s['title'] ?? s['id']} qualities:');
          if (s['allDownloadUrls'] is List) {
            for (var q in s['allDownloadUrls']) {
              debugPrint('  quality: ${q['quality']}, url: ${q['url']}');
            }
          }
        }
      });
    }
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

  void setAudioQuality(String quality) {
    _audioQuality = quality;
    notifyListeners();
  }

  void setDownloadQuality(String quality) {
    _downloadQuality = quality;
    notifyListeners();
  }

  void clearSong() {
    _currentSong = null;
    _isPlaying = false;
    _isSongLoading = false;
    _currentPlaylist = [];
    _currentSongIndex = 0;
    _currentContext = null; // reset context
    notifyListeners();
  }
}
