import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/message_models.dart';
import '../widgets/prompt_bar.dart';
import '../config/system_prompts.dart';
import 'gemma_service.dart';
import 'speech_service.dart';
import 'streaming_tts_service.dart';
import 'text_recognition_service.dart';

class ChatHelpers {
  final GemmaService _service; final StreamingTtsService _streamingTts; final SpeechService _speechService;
  final TextRecognitionService _textRecognition; final VoidCallback _onStateChanged; final Function(String) _showSnackBar;
  String _systemCtx; bool _resetting = false, _isGenerating = false;
  ChatHelpers({
    required GemmaService service, required StreamingTtsService streamingTts, required SpeechService speechService,
    required TextRecognitionService textRecognition, required VoidCallback onStateChanged,
    required Function(String) showSnackBar, required String systemContext,
  }) : _service = service, _streamingTts = streamingTts, _speechService = speechService,
       _textRecognition = textRecognition, _onStateChanged = onStateChanged,
       _showSnackBar = showSnackBar, _systemCtx = systemContext { _streamingTts.isSpeaking.addListener(_onStateChanged); }

  void dispose() => _streamingTts.isSpeaking.removeListener(_onStateChanged);
  bool get resetting => _resetting; bool get isGenerating => _isGenerating;
  bool get isSpeaking => _streamingTts.isSpeaking.value; String get systemContext => _systemCtx;
  void updateSystemContext(String ctx) => _systemCtx = ctx;
  Future<void> _announceError(String e) async {
    try { await _speechService.speak('Error: ${e.replaceAll('Exception:', '').trim()}'); } catch (_) {}
  }
  Future<void> _handleError(Object e, List<ChatMessage> msgs) async {
    await _streamingTts.stopLoading(); msgs.add(ChatMessage.text('Error: $e', isUser: false));
    _isGenerating = false; _onStateChanged(); await _announceError('$e');
  }
  Future<File?> _captureWithEfficientCamera() async {
    if (kIsWeb) throw Exception('Camera not supported on web');
    CameraController? controller;
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception('No cameras available');
      final desc = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      controller = CameraController(desc, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      return File((await controller.takePicture()).path);
    } catch (e) {
      await _announceError('Camera error: $e'); rethrow;
    } finally { await controller?.dispose(); }
  }
  Future<void> _stream(String text, File? img, ChatMessage aiMsg) async {
    final buf = StringBuffer(); int tokens = 0;
    await _service.sendWithStreaming(
      text: '$_systemCtx\nUser: $text', image: img,
      onToken: (tok) {
        buf.write(tok); tokens++; _streamingTts.addText(tok, buf.toString());
        if (tokens % 3 == 0) { aiMsg.text = buf.toString(); _onStateChanged(); }
      },
      onComplete: (stats) async {
        aiMsg..text = buf.toString()..isStreaming = false..stats = stats;
        _isGenerating = false; _onStateChanged(); await _streamingTts.onMessageComplete();
      },
    );
  }
  Future<void> _send({required String prompt, File? imageFile, required List<ChatMessage> msgs, bool isQuickAction = false}) async {
    try {
      msgs.add(imageFile != null ? ChatMessage.withImageFile(prompt, isUser: true, imageFile: imageFile) : ChatMessage.text(prompt, isUser: true));
      final aiMsg = ChatMessage.text('', isUser: false, isStreaming: true);
      msgs.add(aiMsg); _onStateChanged(); await _speechService.playWooshSound();
      _isGenerating = true; _onStateChanged();
      if (!isQuickAction) await _speechService.announceMessageType(imageFile != null);
      await _streamingTts.startLoading();
      String ext = '';
      if (imageFile != null) { try { ext = await _textRecognition.extractTextFromImage(imageFile); } catch (_) {} }
      await _stream(ext.isNotEmpty ? '$prompt\n[TEXT DETECTED: $ext]' : prompt, imageFile, aiMsg);
    } catch (e) { await _handleError(e, msgs); }
  }
  Future<void> captureAndSend(String prompt, List<ChatMessage> msgs, {bool isQuickAction = false}) async {
    try {
      final img = await _captureWithEfficientCamera();
      await _send(prompt: prompt, imageFile: img, msgs: msgs, isQuickAction: isQuickAction);
    } catch (e) { await _handleError(e, msgs); }
  }
  Future<void> sendTextOnly(String prompt, List<ChatMessage> msgs) => _send(prompt: prompt, msgs: msgs);

  Future<void> newChat(List<ChatMessage> messages, GlobalKey<PromptBarState>? key) async {
    if (_resetting) return;
    _streamingTts.reset(); _resetting = true; _onStateChanged();
    await _speechService.speak('Starting new chat');
    messages.clear(); key?.currentState?.clear();
    await _service.resetChatSession();
    _resetting = false; _onStateChanged(); await _speechService.speak('New chat ready');
  }
  Future<void> quickAction1(List<ChatMessage> msgs) => captureAndSend(SystemPrompts.describeRoom, msgs, isQuickAction: true);
  Future<void> quickAction2(List<ChatMessage> msgs) => captureAndSend(SystemPrompts.tellMeWhatYouSee, msgs, isQuickAction: true);
  Future<void> quickAction3(List<ChatMessage> msgs) => captureAndSend(SystemPrompts.whatIsThis, msgs, isQuickAction: true);
  Future<void> quickAction4(List<ChatMessage> msgs) => captureAndSend(SystemPrompts.readText, msgs, isQuickAction: true);
}
