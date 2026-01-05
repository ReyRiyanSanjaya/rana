import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playBeep() async {
    try {
      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }
      await _player.play(AssetSource('sounds/beep.mp3'),
          volume: 0.8, mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Sound Error: $e');
    }
  }

  static Future<void> playSuccess() async {
    try {
      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }
      await _player.play(AssetSource('sounds/success.mp3'),
          volume: 1.0, mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Sound Error: $e');
    }
  }

  static Future<void> playError() async {
    try {
      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }
      // Reusing beep for error for now, or could use a different logic
      await _player.play(AssetSource('sounds/beep.mp3'),
          volume: 1.0, mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Sound Error: $e');
    }
  }
}
