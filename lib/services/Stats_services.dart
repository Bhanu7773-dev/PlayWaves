import 'dart:async';
import 'package:flutter/material.dart';

class MinuteCountService extends ChangeNotifier {
  Duration _listenedDuration = Duration.zero;
  Duration get listenedDuration => _listenedDuration;

  Duration _sessionStart = Duration.zero;
  Duration _lastPosition = Duration.zero;

  bool _isCounting = false;
  Timer? _timer;

  // Start tracking from the given position
  void start(Duration currentPosition) {
    _sessionStart = currentPosition;
    _lastPosition = currentPosition;
    _isCounting = true;
    _startTimer();
    debugPrint('[MinuteCountService] Start: $currentPosition');
  }

  // Pause the counter (e.g. when player paused)
  void pause(Duration currentPosition) {
    _updateDuration(currentPosition);
    _isCounting = false;
    _timer?.cancel();
    debugPrint('[MinuteCountService] Paused at: $currentPosition');
  }

  // Resume from last position
  void resume(Duration currentPosition) {
    _sessionStart = currentPosition;
    _lastPosition = currentPosition;
    _isCounting = true;
    _startTimer();
    debugPrint('[MinuteCountService] Resumed at: $currentPosition');
  }

  // Call when song changes or page is disposed: returns the final listened duration for that song
  Duration end(Duration currentPosition) {
    _updateDuration(currentPosition);
    _timer?.cancel();
    _isCounting = false;
    final result = _listenedDuration;
    debugPrint(
      '[MinuteCountService] Ended at: $currentPosition, Total: $_listenedDuration',
    );
    _reset();
    return result;
  }

  // Internal: update listened duration on pause/end
  void _updateDuration(Duration currentPosition) {
    if (_isCounting) {
      final delta = currentPosition - _lastPosition;
      if (delta > Duration.zero) {
        _listenedDuration += delta;
        notifyListeners();
      }
      _lastPosition = currentPosition;
    }
  }

  // Internal: timer to update progress every second (optional)
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isCounting) {
        // You can update UI here if needed, or just rely on actual position from player
        notifyListeners();
      }
    });
  }

  // Reset for next song
  void _reset() {
    _listenedDuration = Duration.zero;
    _sessionStart = Duration.zero;
    _lastPosition = Duration.zero;
    _isCounting = false;
    _timer?.cancel();
  }
}
