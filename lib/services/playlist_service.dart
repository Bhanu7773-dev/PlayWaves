import 'package:hive/hive.dart';
import '../models/playlist_song.dart';

class PlaylistService {
  static final Box<PlaylistSong> playlistBox = Hive.box<PlaylistSong>(
    'playlistSongs',
  );

  static bool isInPlaylist(String songId) {
    return playlistBox.containsKey(songId);
  }

  static void addToPlaylist(Map<String, dynamic> song) {
    print('Adding to playlist: $song');
    final songId = song['id'] ?? song['songId'] ?? '';
    if (songId.isEmpty) return;
    if (!isInPlaylist(songId)) {
      playlistBox.put(
        songId,
        PlaylistSong(
          id: songId,
          title: song['name'] ?? song['title'] ?? '',
          artist: _getArtistName(song),
          imageUrl: _getImageUrl(song),
          downloadUrl: _getDownloadUrl(song),
        ),
      );
    }
  }

  static void removeFromPlaylist(String songId) {
    playlistBox.delete(songId);
  }

  static String _getArtistName(Map<String, dynamic> song) {
    // Try standard fields first
    final primaryArtists = song['primaryArtists'];
    if (primaryArtists is List) {
      return primaryArtists
          .map((e) {
            if (e is String) return e;
            if (e is Map && e['name'] != null) return e['name'];
            if (e is Map && e['title'] != null) return e['title'];
            return '';
          })
          .where((e) => e.toString().isNotEmpty)
          .join(', ');
    }
    if (primaryArtists is Map && primaryArtists['name'] != null) {
      return primaryArtists['name'];
    }
    if (primaryArtists is String) return primaryArtists;
    if (song['artist'] is String) return song['artist'];
    // Try JioSaavn nested format
    if (song['artists'] is Map && song['artists']['primary'] is List) {
      final primaryList = song['artists']['primary'] as List;
      return primaryList
          .map((e) {
            if (e is String) return e;
            if (e is Map && e['name'] != null) return e['name'];
            return '';
          })
          .where((e) => e.toString().isNotEmpty)
          .join(', ');
    }
    return '';
  }

  static String _getImageUrl(Map<String, dynamic> song) {
    final image = song['image'] ?? song['imageUrl'];
    if (image is List && image.isNotEmpty) {
      // Try to pick the best image (default/high/500x500), fallback to last
      for (var img in image) {
        final quality = (img['quality'] ?? '').toString().toLowerCase();
        if (quality == 'default' || quality == 'high' || quality == '500x500') {
          return img['url'] ?? '';
        }
      }
      final last = image.last;
      if (last is String) return last;
      if (last is Map && last['url'] != null) return last['url'];
      if (last is Map && last['link'] != null) return last['link'];
    }
    if (image is String) return image;
    return '';
  }

  static String _getDownloadUrl(Map<String, dynamic> song) {
    final downloadUrl = song['downloadUrl'];
    if (downloadUrl is List && downloadUrl.isNotEmpty) {
      // Prefer high quality or default, fallback to last
      for (var item in downloadUrl) {
        if (item is Map) {
          final quality = (item['quality'] ?? '').toString().toLowerCase();
          if (quality == 'high' ||
              quality == '320kbps' ||
              quality == 'default') {
            if (item['url'] != null && item['url'].toString().isNotEmpty) {
              return item['url'];
            }
            if (item['link'] != null && item['link'].toString().isNotEmpty) {
              return item['link'];
            }
          }
        } else if (item is String && item.isNotEmpty) {
          return item;
        }
      }
      final last = downloadUrl.last;
      if (last is String) return last;
      if (last is Map && last['url'] != null) return last['url'];
      if (last is Map && last['link'] != null) return last['link'];
    }
    if (downloadUrl is String) return downloadUrl;
    return '';
  }
}
