import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/playlist_song.dart';

class PlaylistSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sync local playlists to Firestore
  static Future<void> syncPlaylistsToFirestore() async {
    try {
      final user = _auth.currentUser;
      print('👤 PLAYLIST SYNC: Current user: ${user?.uid ?? 'null'}');
      if (user == null) {
        print('❌ PLAYLIST SYNC: No authenticated user found');
        return;
      }

      print('🔄 PLAYLIST SYNC: Starting sync for user ${user.uid}');

      final playlistBox = Hive.box<PlaylistSong>('playlistSongs');
      final playlists = playlistBox.values.toList();
      print(
        '📊 PLAYLIST SYNC: Found ${playlists.length} songs in local storage',
      );

      // Convert to Firestore format
      final playlistsData = playlists
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

      print(
        '📤 PLAYLIST SYNC: Preparing to sync ${playlistsData.length} songs to Firestore...',
      );

      // Save to Firestore
      print(
        '☁️ PLAYLIST SYNC: Writing to Firestore path: users/${user.uid}/playlists/my_playlist',
      );
      print('☁️ PLAYLIST SYNC: Data to write: ${playlistsData.length} songs');

      // Try to create the document with explicit data
      final dataToWrite = {
        'songs': playlistsData,
        'lastSynced': DateTime.now()
            .toIso8601String(), // Use regular timestamp instead of server timestamp for testing
        'version': 1,
      };

      print('☁️ PLAYLIST SYNC: Writing data: $dataToWrite');

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .doc('my_playlist');

      await docRef.set(dataToWrite);

      print('☁️ PLAYLIST SYNC: Write operation completed, verifying...');

      // Verify the write by reading back
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final data = snapshot.data();
        final songCount = (data?['songs'] as List?)?.length ?? 0;
        print(
          '✅ PLAYLIST SYNC: Verification successful - ${songCount} songs in Firestore',
        );
      } else {
        print('❌ PLAYLIST SYNC: Verification failed - document does not exist');
      }

      print(
        '✅ PLAYLIST SYNC: Successfully saved ${playlistsData.length} songs to users/${user.uid}/playlists/my_playlist',
      );
      print('Playlists synced to Firestore successfully');
    } catch (e) {
      print('❌ PLAYLIST SYNC ERROR: $e');
      print('❌ PLAYLIST SYNC ERROR: Type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('❌ PLAYLIST SYNC FIREBASE ERROR: ${e.code} - ${e.message}');
        if (e.code == 'permission-denied') {
          print('❌ PLAYLIST SYNC: PERMISSION DENIED - Check Firestore rules');
          print(
            '❌ PLAYLIST SYNC: Make sure Firestore rules allow writes to /users/{userId}/playlists/',
          );
        }
      }
    }
  }

  // Load playlists from Firestore and merge with local
  static Future<void> loadPlaylistsFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .doc('my_playlist')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['songs'] is List) {
          final songsData = data['songs'] as List;
          final playlistBox = Hive.box<PlaylistSong>('playlistSongs');

          // Clear existing and add from Firestore
          await playlistBox.clear();

          for (var songData in songsData) {
            if (songData is Map) {
              final song = PlaylistSong(
                id: songData['id'] ?? '',
                title: songData['title'] ?? '',
                artist: songData['artist'] ?? '',
                imageUrl: songData['imageUrl'] ?? '',
                downloadUrl: songData['downloadUrl'],
              );
              await playlistBox.add(song);
            }
          }

          print('Playlists loaded from Firestore successfully');
        }
      }
    } catch (e) {
      print('Error loading playlists from Firestore: $e');
    }
  }

  // Check if user is logged in
  static bool get isUserLoggedIn {
    return _auth.currentUser != null;
  }

  // Auto-sync when playlist changes (call this when songs are added/removed)
  static Future<void> autoSync() async {
    if (isUserLoggedIn) {
      await syncPlaylistsToFirestore();
    }
  }

  // Initialize sync service (call this when app starts)
  static Future<void> initialize() async {
    if (isUserLoggedIn) {
      await loadPlaylistsFromFirestore();
    }
  }

  // Handle user login - load from Firestore
  static Future<void> onUserLogin() async {
    await loadPlaylistsFromFirestore();
  }

  // Handle user logout - keep local data
  static Future<void> onUserLogout() async {
    // Local data remains in Hive, no action needed
    print('User logged out, keeping local playlists');
  }
}
