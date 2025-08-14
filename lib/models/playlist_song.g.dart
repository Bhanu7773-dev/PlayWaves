// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistSongAdapter extends TypeAdapter<PlaylistSong> {
  @override
  final int typeId = 2;

  @override
  PlaylistSong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistSong(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      imageUrl: fields[3] as String,
      downloadUrl: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistSong obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.downloadUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistSongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
