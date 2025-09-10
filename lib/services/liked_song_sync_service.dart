import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/liked_song.dart';

class LikedSongSyncService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sync local liked songs to Firestore
  static Future<void> syncLikedSongsToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final likedSongsBox = Hive.box<LikedSong>('likedSongs');
      final likedSongs = likedSongsBox.values.toList();

      // Convert to Firestore format
      final likedSongsData = likedSongs
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist,
              'imageUrl': song.imageUrl,
              'downloadUrl': song.downloadUrl,
            },
          )
          .toList();

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('liked_songs')
          .doc('my_liked_songs')
          .set({
            'songs': likedSongsData,
            'lastSynced': FieldValue.serverTimestamp(),
            'version': 1,
          });

      print(
        '✅ LIKED SONGS SYNC: Saved ${likedSongsData.length} songs to users/${user.uid}/liked_songs/my_liked_songs',
      );
      print('Liked songs synced to Firestore successfully');
    } catch (e) {
      print('Error syncing liked songs to Firestore: $e');
    }
  }

  // Load liked songs from Firestore and merge with local
  static Future<void> loadLikedSongsFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final likedSongsBox = Hive.box<LikedSong>('likedSongs');

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('liked_songs')
          .doc('my_liked_songs')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['songs'] is List) {
          final cloudSongs = data['songs'] as List;

          // Convert Firestore data to LikedSong objects and add to local storage
          for (final songData in cloudSongs) {
            if (songData is Map) {
              final songId = songData['id'] ?? '';
              if (songId.isNotEmpty && !likedSongsBox.containsKey(songId)) {
                likedSongsBox.put(
                  songId,
                  LikedSong(
                    id: songId,
                    title: songData['title'] ?? '',
                    artist: songData['artist'] ?? '',
                    imageUrl: songData['imageUrl'] ?? '',
                    downloadUrl: songData['downloadUrl'],
                  ),
                );
              }
            }
          }
        }
      }

      print('Liked songs loaded from Firestore successfully');
    } catch (e) {
      print('❌ LIKED SONGS LOAD ERROR: $e');
    }
  }

  // Auto sync method (called after every change)
  Future<void> autoSync() async {
    final user = _auth.currentUser;
    if (user != null) {
      await syncLikedSongsToFirestore();
    }
  }

  // Initialize sync on login
  static Future<void> initializeSync() async {
    await loadLikedSongsFromFirestore();
    await syncLikedSongsToFirestore();
  }

  // Handle user login - load from Firestore
  static Future<void> onUserLogin() async {
    await loadLikedSongsFromFirestore();
  }

  // Handle user logout - keep local data
  static Future<void> onUserLogout() async {
    // Local data remains in Hive, no action needed
    print('User logged out, keeping local liked songs');
  }
}
