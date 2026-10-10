// lib/chat_page/services/speech_service.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/prompt_bar.dart';
import 'sound_manager.dart';

/// Speech services for blind users: dictation, TTS announcements, and audio feedback
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts; // For accessibility announcements
  final VoidCallback _onStateChanged;
  final GlobalKey<PromptBarState> _promptBarKey;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Dynamic callback to check if AI is generating (prevents speech conflicts)
  bool Function()? _isGeneratingCallback;
  bool _speechEnabled = false;
  bool _listening = false;
  bool _sendButtonPressed =
      false; // Track if user sent message during dictation
  bool _isStoppingDictation = false; // Prevent race conditions

  SpeechService({
    required FlutterTts tts,
    required VoidCallback onStateChanged,
    required GlobalKey<PromptBarState> promptBarKey,
    required bool Function() isGenerating,
  }) : _tts = tts,
       _onStateChanged = onStateChanged,
       _promptBarKey = promptBarKey {
    updateIsGeneratingCallback(isGenerating);
  }

  // Public state accessors
  bool get speechEnabled => _speechEnabled;
  bool get listening => _listening;

  /// Update the callback used to check if AI is currently generating
  void updateIsGeneratingCallback(bool Function() callback) {
    _isGeneratingCallback = callback;
  }

  bool _checkIsGenerating() => _isGeneratingCallback?.call() ?? false;

  /// One-time initialization of speech recognition with auto-resume on status changes
  Future<void> initialize() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          // Auto-resume dictation if it stops unexpectedly while user is still dictating
          if (_listening && !_isStoppingDictation && status == 'notListening') {
            _listenAgain();
          }
        },
        onError: (error) => debugPrint('Speech error: $error'),
      );
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    } finally {
      _onStateChanged();
    }
  }

  /* Audio feedback and announcements */

  /// Play satisfying sound when messages are sent
  Future<void> playWooshSound() => SoundManager.instance.playWoosh();

  /// Brief accessibility announcement for message types (text vs photo)
  Future<void> announceMessageType(bool hasPhoto) async {
    final msg = hasPhoto ? 'Sending text with photo' : 'Sending text only';
    _announce(msg);
  }

  /// General TTS for accessibility announcements (not streaming content)
  Future<void> speak(String message) async => _announce(message.trim());

  /// Use system accessibility announcements for brief notifications
  void _announce(String message) {
    if (message.isEmpty) return;
    debugPrint('supported: ${SemanticsService.isAnnounceSupported()}');
    if (Platform.isAndroid) {
      SemanticsService.isAnnounceSupported()
          ? SemanticsService.announce(message, ui.TextDirection.ltr)
          : _tts.speak(message);
    } else {
      _tts.speak(message);
    }
  }

  /* Voice dictation functionality */

  /// Start continuous dictation with audio feedback
  Future<void> startDictation() async {
    // Don't start dictation while AI is generating or if speech not available
    if (!_speechEnabled || _checkIsGenerating()) return;

    if (!_listening) {
      _listening = true;
      _sendButtonPressed = false;
      _isStoppingDictation = false;
      _onStateChanged();
    }

    await _playDictationStartSound();
    _listenAgain(); // Start the actual speech recognition
  }

  /// Stop dictation with audio feedback and read back recognized text
  Future<void> stopDictation() async {
    if (!_listening || _isStoppingDictation) return;
    _isStoppingDictation = true;

    try {
      _listening = false;
      await _speech.stop();
      await _playDictationStopSound();

      // Read back the dictated text unless user already sent the message
      final currentText = _promptBarKey.currentState?.currentText ?? '';
      if (!_sendButtonPressed && currentText.trim().isNotEmpty) {
        _announce(currentText.trim());
      }
    } finally {
      _sendButtonPressed = false;
      _isStoppingDictation = false;
      _onStateChanged();
    }
  }

  /// Stop any ongoing TTS (used when user wants to interrupt AI reading)
  Future<void> stopTts() async {
    try {
      // Mark that send button was pressed to avoid reading back dictated text
      if (_listening) _sendButtonPressed = true;
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  /// Toggle dictation on/off
  Future<void> toggleDictation() =>
      _listening ? stopDictation() : startDictation();

  /* Speech recognition engine */

  /// Start a new speech recognition session with continuous listening
  void _listenAgain() {
    if (_isStoppingDictation || !_listening) return;

    _speech.listen(
      onResult: (val) {
        if (!_listening || _isStoppingDictation) return;
        // Update prompt bar with recognized text in real-time
        _promptBarKey.currentState?.updateText(val.recognizedWords.trim());
      },
      listenFor: const Duration(minutes: 5), // Long session for complex prompts
      pauseFor: const Duration(seconds: 60), // Handle pauses in speech
      partialResults: true, // Show text as it's being recognized
      cancelOnError: false, // Continue listening despite errors
      listenMode: ListenMode.dictation, // Optimized for text dictation
    );
  }

  /* Audio feedback using asset files with fallbacks */

  /// Play start sound with fallback to system sound + haptic
  Future<void> _playDictationStartSound() async {
    try {
      await _audioPlayer.play(AssetSource('dictation_start.mp3'));
    } catch (e) {
      debugPrint('Error playing dictation start sound: $e');
      SystemSound.play(SystemSoundType.click); // Fallback
    }
  }

  /// Play stop sound with fallback to system sound + haptic
  Future<void> _playDictationStopSound() async {
    try {
      await _audioPlayer.play(AssetSource('dictation_stop.mp3'));
    } catch (e) {
      debugPrint('Error playing dictation stop sound: $e');
      SystemSound.play(SystemSoundType.click); // Fallback
    }
  }

  /* Cleanup and misc */

  /// Keyboard event handler (currently pass-through)
  KeyEventResult handleFocusKey(FocusNode _, KeyEvent __) =>
      KeyEventResult.ignored;

  void dispose() {
    _speech.stop();
    _speech.cancel();
    _audioPlayer.dispose();
  }
}
