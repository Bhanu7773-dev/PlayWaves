import 'package:hive/hive.dart';

part 'playlist_song.g.dart';

@HiveType(typeId: 2)
class PlaylistSong extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String artist;

  @HiveField(3)
  String imageUrl;

  @HiveField(4)
  String? downloadUrl;

  PlaylistSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.downloadUrl,
  });
}
