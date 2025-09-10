import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataCleanupService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Clear all user data from Firestore
  static Future<void> clearAllUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      // Delete playlists collection
      final playlistsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('playlists');

      final playlistsSnapshot = await playlistsRef.get();
      for (final doc in playlistsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete liked_songs collection
      final likedSongsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('liked_songs');

      final likedSongsSnapshot = await likedSongsRef.get();
      for (final doc in likedSongsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('All user data cleared from Firestore successfully');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
