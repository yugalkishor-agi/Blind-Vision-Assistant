// lib/chat_page/services/sound_manager.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Centralized audio management for app sounds with fallback handling
/// Manages multiple audio players for different sound types to avoid conflicts
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  static SoundManager get instance => _instance;

  // Separate players for different audio types to prevent interference
  final AudioPlayer _audioPlayer = AudioPlayer(); // General sounds
  final AudioPlayer _loadingPlayer = AudioPlayer(); // Loading loop
  final AudioPlayer _dictationPlayer = AudioPlayer(); // Speech feedback
  bool _isLoadingPlaying = false;

  SoundManager._internal();

  /// Play satisfying woosh sound when messages are sent (max volume for feedback)
  Future<void> playWoosh() async {
    try {
      await _audioPlayer.setVolume(1.0); // Maximum volume for clear feedback
      await _audioPlayer.play(AssetSource('woosh.mp3'));
    } catch (e) {
      print('Error playing woosh sound: $e');
      // Graceful fallback to system sound
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play dictation start sound with fallback to haptic feedback
  Future<void> playDictationStart() async {
    try {
      await _dictationPlayer.setVolume(1.0); // Max volume for accessibility
      await _dictationPlayer.play(AssetSource('dictation_start.mp3'));
      print('Playing dictation start sound');
    } catch (e) {
      print('Error playing dictation start sound: $e');
      // Multi-modal fallback: haptic + system sound
      await HapticFeedback.lightImpact();
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play dictation stop sound with fallback to haptic feedback
  Future<void> playDictationStop() async {
    try {
      await _dictationPlayer.setVolume(1.0); // Max volume for accessibility
      await _dictationPlayer.play(AssetSource('dictation_stop.mp3'));
      print('Playing dictation stop sound');
    } catch (e) {
      print('Error playing dictation stop sound: $e');
      // Stronger haptic feedback for "stop" action
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Start looping loading sound during AI processing
  Future<void> playLoading() async {
    if (_isLoadingPlaying) return; // Prevent duplicate loading sounds

    try {
      _isLoadingPlaying = true;
      await _loadingPlayer.setReleaseMode(ReleaseMode.loop); // Continuous loop
      await _loadingPlayer.setVolume(0.8); // Slightly lower than UI sounds
      await _loadingPlayer.play(AssetSource('loading.mp3'));
    } catch (e) {
      _isLoadingPlaying = false;
      print('Error playing loading sound: $e');
    }
  }

  /// Stop loading sound when AI processing completes
  Future<void> stopLoading() async {
    if (!_isLoadingPlaying) return;

    try {
      _isLoadingPlaying = false;
      await _loadingPlayer.stop();
    } catch (e) {
      print('Error stopping loading sound: $e');
    }
  }

  /// Pause loading sound temporarily (e.g., when TTS starts speaking)
  Future<void> pauseLoading() async {
    if (!_isLoadingPlaying) return;

    try {
      await _loadingPlayer.pause();
    } catch (e) {
      print('Error pausing loading sound: $e');
    }
  }

  /// Resume loading sound after temporary pause
  Future<void> resumeLoading() async {
    if (!_isLoadingPlaying) return;

    try {
      await _loadingPlayer.resume();
    } catch (e) {
      print('Error resuming loading sound: $e');
    }
  }

  /// Clean up all audio players
  void dispose() {
    _audioPlayer.dispose();
    _loadingPlayer.dispose();
    _dictationPlayer.dispose();
  }
}
