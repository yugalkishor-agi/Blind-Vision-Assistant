import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  TextRecognitionService._internal();
  static final TextRecognitionService instance = TextRecognitionService._internal();

  late final TextRecognizer _recognizer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initialized = true;
  }

  Future<String> extractTextFromImage(File? imageFile) async {
    if (!_initialized || imageFile == null) return '';
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } catch (_) {
      return '';
    }
  }

  Future<void> dispose() async {
    if (_initialized) {
      await _recognizer.close();
      _initialized = false;
    }
  }
}
