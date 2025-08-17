import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    // Listen for player events and update playback state for notification
    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent());
    });
    // Initial state
    playbackState.add(_transformEvent());
  }

  PlaybackState _transformEvent() {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
        MediaControl(
          label: 'Close',
          action: MediaAction.stop,
          androidIcon: 'drawable/ic_close',
        ),
      ],
      androidCompactActionIndices: const [0, 1, 2], // prev/play/pause/next
      playing: _player.playing,
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      updateTime: DateTime.now(),
    );
  }

  // Implement required methods for controls
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> skipToNext() => _player.seekToNext();
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
  @override
  Future<void> stop() => _player.stop();

  @override
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'close') {
      await stop();
    } else if (name == 'favorite') {
      print('Favorite pressed!');
    }
  }
}
