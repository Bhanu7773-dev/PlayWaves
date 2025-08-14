import 'package:hive/hive.dart';

part 'liked_song.g.dart';

@HiveType(typeId: 0)
class LikedSong extends HiveObject {
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

  LikedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.downloadUrl,
  });
}
