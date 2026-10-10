import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StreamingTtsService {
  final FlutterTts _tts;
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  final StringBuffer _buffer = StringBuffer();

  StreamingTtsService(this._tts);

  Future<void> startLoading() async {
    isSpeaking.value = true;
  }

  Future<void> stopLoading() async {
    isSpeaking.value = false;
  }

  void addText(String token, String fullText) {
    _buffer.write(token);
    if (token.contains(RegExp(r'[.!?]'))) {
      _speakBuffer();
    }
  }

  void _speakBuffer() {
    final text = _buffer.toString().trim();
    if (text.isNotEmpty) {
      _tts.speak(text);
      _buffer.clear();
    }
  }

  Future<void> onMessageComplete() async {
    _speakBuffer();
  }

  void reset() {
    _buffer.clear();
    _tts.stop();
    isSpeaking.value = false;
  }

  void stop() {
    reset();
  }
}
