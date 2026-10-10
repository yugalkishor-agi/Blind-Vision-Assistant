import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../widgets/prompt_bar.dart';
import 'sound_manager.dart';

class SpeechService {
  final FlutterTts _tts;
  final SpeechToText _stt = SpeechToText();
  final SoundManager _sounds = SoundManager();
  final GlobalKey<PromptBarState> _promptBarKey;
  final VoidCallback _onStateChanged;
  Function() _isGenerating;

  bool speechEnabled = false;
  bool listening = false;

  SpeechService({
    required FlutterTts tts,
    required VoidCallback onStateChanged,
    required GlobalKey<PromptBarState> promptBarKey,
    required Function() isGenerating,
  })  : _tts = tts,
        _onStateChanged = onStateChanged,
        _promptBarKey = promptBarKey,
        _isGenerating = isGenerating;

  void updateIsGeneratingCallback(Function() cb) => _isGenerating = cb;

  Future<void> initialize() async {
    speechEnabled = await _stt.initialize();
    _onStateChanged();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopTts() async {
    await _tts.stop();
  }

  Future<void> playWooshSound() async {
    await _sounds.playWoosh();
  }

  Future<void> announceMessageType(bool hasImage) async {
    await _tts.speak(hasImage ? 'Photo message' : 'Text message');
  }

  Future<void> toggleDictation() async {
    if (!speechEnabled) return;
    if (listening) {
      await _stt.stop();
      await _sounds.playDictationStop();
      listening = false;
      _onStateChanged();
    } else {
      await _sounds.playDictationStart();
      listening = true;
      _onStateChanged();
      await _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            _promptBarKey.currentState?.setText(result.recognizedWords);
            listening = false;
            _onStateChanged();
          }
        },
        listenOptions: SpeechListenOptions(cancelOnError: true),
      );
    }
  }

  KeyEventResult handleFocusKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        toggleDictation();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void dispose() {
    _stt.cancel();
    _sounds.dispose();
  }
}
