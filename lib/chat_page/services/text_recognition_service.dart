// lib/chat_page/services/text_recognition_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for on-device text recognition using Google ML Kit
class TextRecognitionService {
  static final TextRecognitionService _instance =
      TextRecognitionService._internal();
  static TextRecognitionService get instance => _instance;

  TextRecognitionService._internal();

  late final TextRecognizer _textRecognizer;
  bool _initialized = false;

  /// Initialize the text recognizer
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _textRecognizer = TextRecognizer(
        script: TextRecognitionScript
            .latin, // You can change this based on your needs
      );
      _initialized = true;
      debugPrint('[TextRecognitionService] Initialized successfully');
    } catch (e) {
      debugPrint('[TextRecognitionService] Initialization error: $e');
      rethrow;
    }
  }

  /// Extract text from an image file
  Future<String> extractTextFromImage(File imageFile) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        debugPrint('[TextRecognitionService] No text detected in image');
        return '';
      }

      debugPrint(
        '[TextRecognitionService] Extracted text: ${recognizedText.text}',
      );
      return recognizedText.text;
    } catch (e) {
      debugPrint('[TextRecognitionService] Text extraction error: $e');
      // Don't throw error - just return empty string so the app continues to work
      return '';
    }
  }

  /// Extract text with additional metadata (blocks, lines, elements)
  Future<TextExtractionResult> extractTextWithMetadata(File imageFile) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final blocks = <String>[];
      final lines = <String>[];

      for (TextBlock block in recognizedText.blocks) {
        blocks.add(block.text);
        for (TextLine line in block.lines) {
          lines.add(line.text);
        }
      }

      return TextExtractionResult(
        fullText: recognizedText.text,
        blocks: blocks,
        lines: lines,
      );
    } catch (e) {
      debugPrint(
        '[TextRecognitionService] Text extraction with metadata error: $e',
      );
      return TextExtractionResult(fullText: '', blocks: [], lines: []);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_initialized) {
      await _textRecognizer.close();
      _initialized = false;
      debugPrint('[TextRecognitionService] Disposed');
    }
  }
}

/// Result class for text extraction with metadata
class TextExtractionResult {
  final String fullText;
  final List<String> blocks;
  final List<String> lines;

  TextExtractionResult({
    required this.fullText,
    required this.blocks,
    required this.lines,
  });

  bool get hasText => fullText.isNotEmpty;

  @override
  String toString() {
    return 'TextExtractionResult(text: "${fullText.length > 50 ? '${fullText.substring(0, 50)}...' : fullText}", blocks: ${blocks.length}, lines: ${lines.length})';
  }
}
