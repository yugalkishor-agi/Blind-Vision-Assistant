import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playWoosh() async {
    try {
      await _player.play(AssetSource('woosh.mp3'));
    } catch (_) {}
  }

  Future<void> playDictationStart() async {
    try {
      await _player.play(AssetSource('dictation_start.mp3'));
    } catch (_) {}
  }

  Future<void> playDictationStop() async {
    try {
      await _player.play(AssetSource('dictation_stop.mp3'));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
