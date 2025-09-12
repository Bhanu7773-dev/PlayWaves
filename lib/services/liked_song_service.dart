import 'package:hive/hive.dart';
import 'package:playwaves/services/liked_songs_sync_service.dart';
import '../models/liked_song.dart';
import 'liked_songs_sync_service.dart';

class LikedSongService {
  static final Box<LikedSong> likedSongsBox = Hive.box<LikedSong>('likedSongs');

  static bool isLiked(String songId) {
    return likedSongsBox.containsKey(songId);
  }

  static Future<void> addToLikedSongs(Map<String, dynamic> song) async {
    final songId = song['id'] ?? song['title'] ?? '';
    if (songId.isEmpty || isLiked(songId)) return;

    String imageUrl = '';
    final img = song['image'];
    if (img is List && img.isNotEmpty) {
      for (var item in img) {
        if (item is Map &&
            item['link'] != null &&
            item['link'].toString().contains('500x500')) {
          imageUrl = item['link'];
          break;
        }
      }
      if (imageUrl.isEmpty) {
        for (var item in img.reversed) {
          if (item is Map &&
              item['link'] != null &&
              item['link'].toString().isNotEmpty) {
            imageUrl = item['link'];
            break;
          }
          if (item is Map &&
              item['url'] != null &&
              item['url'].toString().isNotEmpty) {
            imageUrl = item['url'];
            break;
          }
        }
      }
      if (imageUrl.isEmpty && img.last is Map && img.last['link'] != null) {
        imageUrl = img.last['link'];
      }
    } else if (img is String && img.isNotEmpty) {
      imageUrl = img;
    }

    String artistName = '';
    if (song['artists'] != null &&
        song['artists'] is Map &&
        song['artists']['primary'] is List &&
        (song['artists']['primary'] as List).isNotEmpty) {
      artistName = song['artists']['primary'][0]['name'] ?? '';
    } else if (song['primaryArtists'] != null &&
        song['primaryArtists'].toString().isNotEmpty) {
      artistName = song['primaryArtists'];
    } else if (song['subtitle'] != null &&
        song['subtitle'].toString().isNotEmpty) {
      artistName = song['subtitle'];
    }

    String downloadUrl = '';
    if (song['downloadUrl'] != null &&
        song['downloadUrl'] is List &&
        (song['downloadUrl'] as List).isNotEmpty) {
      final urlObj = (song['downloadUrl'] as List).last;
      if (urlObj is Map && urlObj['url'] != null) {
        downloadUrl = urlObj['url'];
      }
    } else if (song['media_url'] != null) {
      downloadUrl = song['media_url'];
    } else if (song['media_preview_url'] != null) {
      downloadUrl = song['media_preview_url'];
    }

    likedSongsBox.put(
      songId,
      LikedSong(
        id: songId,
        title: song['name'] ?? song['title'] ?? '',
        artist: artistName,
        imageUrl: imageUrl,
        downloadUrl: downloadUrl,
      ),
    );

    // Sync to cloud after adding
    await LikedSongSyncService().autoSync();
    print('❤️ LIKED SONGS: Added song and synced to cloud');
  }

  static Future<void> removeFromLikedSongs(String songId) async {
    likedSongsBox.delete(songId);
    // Sync to cloud after removing
    await LikedSongSyncService().autoSync();
    print('💔 LIKED SONGS: Removed song and synced to cloud');
  }

  static Future<void> clearLikedSongs() async {
    likedSongsBox.clear();
    // Sync to cloud after clearing
    await LikedSongSyncService().autoSync();
    print('🗑️ LIKED SONGS: Cleared all songs and synced to cloud');
  }
}
