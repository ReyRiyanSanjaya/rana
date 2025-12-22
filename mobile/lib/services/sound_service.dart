// import 'package:audioplayers/audioplayers.dart'; // UNCOMMENT AFTER running 'flutter pub get'

class SoundService {
  // static final AudioPlayer _player = AudioPlayer(); // UNCOMMENT AFTER running 'flutter pub get'

  static Future<void> playBeep() async {
    try {
      // await _player.play(AssetSource('sounds/beep.mp3'));
      print('Sound: Beep (Run flutter pub get to enable real sound)'); 
    } catch (e) {
      // ignore
    }
  }

  static Future<void> playSuccess() async {
    try {
       // await _player.play(AssetSource('sounds/success.mp3'));
       print('Sound: Success (Run flutter pub get to enable real sound)');
    } catch (e) {
      // ignore
    }
  }
}

