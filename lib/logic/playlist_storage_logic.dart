import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/liked_song.dart';
import '../models/playlist_song.dart';

class PlaylistStorageLogic {
  static void openRecentlyPlayedBox() {
    Hive.openBox<PlaylistSong>('recentlyPlayed');
  }

  static int getLikedSongsCount() {
    return Hive.box<LikedSong>('likedSongs').length;
  }

  static int getPlaylistSongsCount() {
    return Hive.box<PlaylistSong>('playlistSongs').length;
  }

  static AnimationController createMasterController(TickerProvider vsync) {
    return AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );
  }

  static AnimationController createFloatController(TickerProvider vsync) {
    return AnimationController(
      duration: const Duration(seconds: 8),
      vsync: vsync,
    );
  }

  static Animation<double> createFadeAnimation(
    AnimationController masterController,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: masterController, curve: Curves.easeOut));
  }

  static Animation<Offset> createSlideAnimation(
    AnimationController masterController,
  ) {
    return Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: masterController, curve: Curves.easeOut));
  }

  static Animation<double> createFloatAnimation(
    AnimationController floatController,
  ) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
    );
  }
}
