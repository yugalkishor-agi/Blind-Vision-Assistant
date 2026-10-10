// lib/chat_page/services/streaming_tts_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:remove_markdown/remove_markdown.dart';
import 'sound_manager.dart';

/// Internal representation of a segment with its start index in the cleaned text.
class _Segment {
  final String text;
  final int start; // start index in cleaned buffer
  _Segment(this.text, this.start);
}

/// Streaming TTS Service for reading AI responses as they're generated.
class StreamingTtsService {
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  final FlutterTts _tts;

  // Buffers & state
  final List<_Segment> _pendingSegments = [];
  String _buffer = '';
  String _previousSegment = '';

  // Counters & flags
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _messageComplete = false;
  int _lastSpokenLength = 0; // position in the *cleaned* text

  int _lastProgressEnd = 0; // global position in cleaned text from progress
  int _currentSegmentStart = 0;

  // Resume strategy ---------------------------------------------------
  int _resumeAttempts = 0;
  static const int _maxResumeAttempts = 5;
  static const Duration _resumeDelay = Duration(seconds: 6); // TalkBack ~5 s
  bool _resumeScheduled = false;
  bool _suppressResumeOnCancel = false;

  StreamingTtsService(this._tts) {
    _configureTts();
  }

  void _configureTts() {
    _tts.setSpeechRate(0.5);
    _tts.setVolume(0.9);
    _tts.setPitch(1.0);
    _tts.awaitSpeakCompletion(true);

    // Callbacks -------------------------------------------------------
    _tts.setStartHandler(() {
      _resumeScheduled = false;
    });

    _tts.setProgressHandler((String text, int start, int end, String word) {
      // progress is relative to current segment; map to global cleaned buffer index
      _lastProgressEnd = _currentSegmentStart + end;
    });

    _tts.setCompletionHandler(() {
      _resumeAttempts = 0;
    });

    _tts.setCancelHandler(() {
      if (!_suppressResumeOnCancel) _scheduleResume();
    });

    _tts.setPauseHandler(() {
      if (!_suppressResumeOnCancel) _scheduleResume();
    });
  }

  void _scheduleResume() {
    if (_resumeScheduled || _resumeAttempts >= _maxResumeAttempts) return;
    _resumeAttempts++;
    _resumeScheduled = true;

    final cleanBuffer = _cleanTextForTts(_buffer);
    int resumeFrom = _lastProgressEnd;
    if (resumeFrom <= 0 || resumeFrom < _lastSpokenLength - 5) {
      resumeFrom = _lastSpokenLength;
    }
    resumeFrom = resumeFrom.clamp(0, cleanBuffer.length);

    Future.delayed(_resumeDelay, () {
      _resumeScheduled = false;
      _speak(from: resumeFrom);
    });
  }

  Future<void> _speak({int from = 0}) async {
    final cleanBuffer = _cleanTextForTts(_buffer);
    final String text = from < cleanBuffer.length
        ? cleanBuffer.substring(from)
        : '';

    // Only force stop if we're regressing significantly to avoid clicks
    final bool shouldForceStop = from < _lastProgressEnd - 10;
    if (shouldForceStop) {
      _suppressResumeOnCancel = true;
      try {
        await _tts.stop();
      } catch (_) {}
      _suppressResumeOnCancel = false;
    }

    if (text.isEmpty) return;

    try {
      await _tts.speak(text, focus: false);
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────────────
  // PUBLIC API
  // ───────────────────────────────────────────
  Future<void> startLoading() async {
    if (_isLoading) return;
    _isLoading = true;
    _resetState();
    await SoundManager.instance.playLoading();
  }

  Future<void> stopLoading() async {
    if (!_isLoading) return;
    _isLoading = false;
    await SoundManager.instance.stopLoading();
  }

  /// Consume one streaming token.
  /// Starts speaking once a complete sentence arrives.
  void addText(String newToken, String currentFullText) {
    _buffer = currentFullText;

    // Immediately process buffer on any new token
    _processBuffer();
  }

  Future<void> onMessageComplete() async {
    _messageComplete = true;
    await stopLoading();
    await _forceCompleteReading();
  }

  void stop() => _hardReset();
  void reset() => _hardReset();

  void dispose() {
    _hardReset();
    isSpeaking.dispose();
  }

  // ────────────────────────────────────────────────
  // BUFFER HANDLING ( now sentence-based )
  // ────────────────────────────────────────────────
  Future<void> _processBuffer() async {
    final cleanText = _cleanTextForTts(_buffer);
    if (cleanText.isEmpty || _isProcessing) return;
    if (cleanText.length <= _lastSpokenLength) return;

    final newContent = cleanText.substring(_lastSpokenLength);

    // Collect only complete sentences; leave any trailing fragment for later
    final sentences = _findCompleteSentences(newContent);
    if (sentences.isEmpty) return;

    int offset = _lastSpokenLength;
    for (final sentence in sentences) {
      _pendingSegments.add(_Segment(sentence.trim(), offset));
      offset += sentence.length;
    }
    _lastSpokenLength = offset;

    if (!_isProcessing) {
      await _processNextSegment();
    }
  }

  Future<void> _processNextSegment() async {
    if (_isProcessing) return;

    while (_pendingSegments.isNotEmpty) {
      _isProcessing = true;

      if (!isSpeaking.value) {
        if (_isLoading) await SoundManager.instance.pauseLoading();
        isSpeaking.value = true;
      }

      final segmentObj = _pendingSegments.removeAt(0);
      final segment = segmentObj.text.trim();
      _currentSegmentStart = segmentObj.start;

      if (segment.isEmpty || segment == _previousSegment) continue;
      if (RegExp(r'^[.!?,;:]+$').hasMatch(segment) &&
          _pendingSegments.isNotEmpty)
        continue;

      try {
        await _tts.speak(segment);
        _previousSegment = segment;
      } catch (_) {
        break;
      }
    }

    _isProcessing = false;

    if (_pendingSegments.isEmpty) {
      if (_messageComplete) {
        await _forceCompleteReading();
      } else {
        final unspoken = _getUnspokenText();
        if (unspoken.trim().isEmpty) {
          isSpeaking.value = false;
          if (_isLoading) await SoundManager.instance.resumeLoading();
        }
      }
    }
  }

  // ───────────────────────────────────────────────
  // FORCE COMPLETE
  // ───────────────────────────────────────────────
  Future<void> _forceCompleteReading() async {
    final cleanBuffer = _cleanTextForTts(_buffer);

    if (cleanBuffer.trim().isEmpty) {
      isSpeaking.value = false;
      return;
    }

    final unspoken = cleanBuffer.length > _lastSpokenLength
        ? cleanBuffer.substring(_lastSpokenLength).trim()
        : '';

    if (unspoken.isNotEmpty) {
      _pendingSegments.add(_Segment(unspoken, _lastSpokenLength));
      _lastSpokenLength = cleanBuffer.length;
      if (!_isProcessing) await _processNextSegment();
    } else {
      isSpeaking.value = false;
    }
  }

  // ───────────────────────────────────────────────
  // TEXT UTILITIES
  // ───────────────────────────────────────────────
  String _getUnspokenText() {
    final cleaned = _cleanTextForTts(_buffer);
    if (cleaned.length <= _lastSpokenLength) return '';
    return cleaned.substring(_lastSpokenLength).trim();
  }

  List<String> _findCompleteSentences(String text) {
    final out = <String>[];

    // 1. Full sentences
    final endRx = RegExp(r'[.!?]+(?:\s+|$)');
    int last = 0;
    for (final m in endRx.allMatches(text)) {
      final chunk = text.substring(last, m.end).trim();
      if (chunk.length > 2) out.add(chunk);
      last = m.end;
    }
    if (out.isNotEmpty) return out;

    // 2. Clause breaks
    final breakRx = RegExp(
      r'[,;:]\s+|\s+(?:and|but|or|however|therefore|meanwhile|also|then|next|first|second|finally|because|since|while|when|where|after|before)\s+',
    );
    last = 0;
    for (final m in breakRx.allMatches(text)) {
      final chunk = text.substring(last, m.end).trim();
      if (chunk.length > 4) out.add(chunk);
      last = m.end;
    }
    if (out.isNotEmpty) return out;

    // 3. Word-count fallback
    if (text.length > 8) {
      final words = text.split(' ');
      var buf = '';
      for (final w in words) {
        if ((buf + ' ' + w).trim().length <= 25) {
          buf = [buf, w].where((s) => s.isNotEmpty).join(' ');
        } else {
          if (buf.isNotEmpty) out.add(buf);
          buf = w;
        }
      }
      if (buf.isNotEmpty) out.add(buf);
    }
    return out;
  }

  /// Strip Markdown & normalize whitespace but **keep single `. ! ?`**.
  String _cleanTextForTts(String text) {
    String cleanedText = text
        .removeMarkdown()
        .replaceAll(RegExp(r'\n+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        // Collapse runs of punctuation without deleting the mark
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAll(RegExp(r'([!?]){2,}'), r'$1')
        .replaceAll(RegExp(r'[,;:]{2,}'), ',');
    return cleanedText.trim();
  }

  // ───────────────────────────────────────────────
  // RESET & CLEANUP
  // ───────────────────────────────────────────────
  void _resetState() {
    _messageComplete = false;
    _buffer = '';
    _lastSpokenLength = 0;
    _pendingSegments.clear();
    _isProcessing = false;
    _previousSegment = '';
    isSpeaking.value = false;
    _lastProgressEnd = 0;
    _currentSegmentStart = 0;
    _resumeAttempts = 0;
    _resumeScheduled = false;
    _suppressResumeOnCancel = false;
  }

  void _hardReset() {
    _tts.stop();
    _resetState();
    stopLoading();
  }
}
