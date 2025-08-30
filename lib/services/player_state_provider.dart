import 'package:flutter/material.dart';

class PlayerStateProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentSong;
  List<Map<String, dynamic>> _currentPlaylist = [];
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

  // Quality normalization method - converts display quality to API quality string
  String _normalizeQuality(String quality) {
    final q = quality.trim().toLowerCase();
    if (q.contains('320')) return '320kbps';
    if (q.contains('160')) return '160kbps';
    if (q.contains('96')) return '96kbps';
    if (q.contains('48')) return '48kbps';
    if (q.contains('12')) return '12kbps';
    return '320kbps'; // Default fallback
  }

  // Transform URL quality suffix (e.g., song_12.mp4 → song_320.mp4)
  String _transformUrlQuality(String url, String targetQuality) {
    final qualityNumber = targetQuality.replaceAll('kbps', '');
    // Transform common patterns
    final patterns = [
      RegExp(r'_(\d+)\.mp4$'),
      RegExp(r'_(\d+)\.m4a$'),
      RegExp(r'_(\d+)\.aac$'),
    ];
    
    for (final pattern in patterns) {
      if (pattern.hasMatch(url)) {
        return url.replaceFirstMapped(pattern, (match) => '_$qualityNumber.${match.group(0)!.split('.').last}');
      }
    }
    return url;
  }

  // Get playable URL for current song using user's audio quality preference
  String? getCurrentPlayableUrl() {
    return getPlayableUrlForSong(_currentSong);
  }

  // Get playable URL for any song using user's audio quality preference
  String? getPlayableUrlForSong(Map<String, dynamic>? song) {
    if (song == null) return null;

    final preferredQuality = _normalizeQuality(_audioQuality ?? '320kbps');
    print('🎵 Playing with quality preference: $preferredQuality');
    
    // First try to find URL from downloadUrl array with matching quality
    final downloadUrl = song['downloadUrl'];
    if (downloadUrl is List && downloadUrl.isNotEmpty) {
      // Look for exact quality match first
      for (var item in downloadUrl) {
        if (item is Map) {
          final quality = (item['quality'] ?? '').toString().toLowerCase();
          if (quality == preferredQuality.toLowerCase() || 
              quality.contains(preferredQuality.replaceAll('kbps', ''))) {
            final url = item['url'] ?? item['link'];
            if (url != null && url.toString().isNotEmpty) {
              print('🎵 Found matching quality URL: $url');
              return url.toString();
            }
          }
        }
      }
      
      // Fallback: try to transform the last URL to target quality
      final lastItem = downloadUrl.last;
      if (lastItem is Map && lastItem['url'] != null) {
        final originalUrl = lastItem['url'].toString();
        final transformedUrl = _transformUrlQuality(originalUrl, preferredQuality);
        if (transformedUrl != originalUrl) {
          print('🎵 Transformed URL quality: $originalUrl → $transformedUrl');
          return transformedUrl;
        }
        print('⚠️ Using original URL: $originalUrl');
        return originalUrl;
      } else if (lastItem is String) {
        final transformedUrl = _transformUrlQuality(lastItem, preferredQuality);
        if (transformedUrl != lastItem) {
          print('🎵 Transformed URL quality: $lastItem → $transformedUrl');
          return transformedUrl;
        }
        print('⚠️ Using direct string URL: $lastItem');
        return lastItem;
      }
    }
    
    // Fallback to other URL fields
    final fallbackUrl = song['media_preview_url'] ?? 
                       song['media_url'] ?? 
                       song['preview_url'] ?? 
                       song['stream_url'];
    
    if (fallbackUrl != null) {
      final transformedUrl = _transformUrlQuality(fallbackUrl.toString(), preferredQuality);
      if (transformedUrl != fallbackUrl.toString()) {
        print('🎵 Transformed fallback URL: $fallbackUrl → $transformedUrl');
        return transformedUrl;
      }
      print('⚠️ Using fallback URL: $fallbackUrl');
      return fallbackUrl.toString();
    }
    
    return null;
  }
}
