import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playBeep() async {
    try {
      await _player.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('Sound Error: $e');
    }
  }

  static Future<void> playSuccess() async {
    try {
       await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('Sound Error: $e');
    }
  }
}

