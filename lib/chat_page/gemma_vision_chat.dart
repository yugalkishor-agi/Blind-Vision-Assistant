import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'widgets/prompt_bar.dart';
import 'services/bootstrap_manager.dart';
import 'services/chat_helpers.dart';
import 'services/speech_service.dart';
import 'services/streaming_tts_service.dart';
import 'services/text_recognition_service.dart';
import 'models/message_models.dart';
import '../error_recovery_page.dart';
import 'handlers/keyboard_handler.dart';
import 'widgets/chat_ui_builder.dart';
import '../settings_page.dart';
import 'widgets/semantic_button_registry.dart';
import 'config/system_prompts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);
  @override State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final _msgs = <ChatMessage>[];
  bool _showMessages = false, _initialising = true, _redirectedOnError = false, _disposed = false;
  late FlutterTts _tts = FlutterTts();
  late StreamingTtsService _streamingTts = StreamingTtsService(_tts);
  ChatHelpers? _chatHelpers; SpeechService? _speechService; KeyboardHandler? _keyboardHandler; TextRecognitionService? _textRecognition;
  String _systemCtx = SystemPrompts.blindUserNavigation; PreferredBackend _backend = PreferredBackend.cpu;
  final _promptBarKey = GlobalKey<PromptBarState>(); final _rootFocus = FocusNode(); final _scrollController = ScrollController();
  late AnimationController _fadeController; late Animation<double> _fadeAnimation;

  @override void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)); _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_disposed) return;
    try {
      final res = await BootstrapManager.bootstrap(
        context: context, systemContext: _systemCtx, backend: _backend, promptBarKey: _promptBarKey,
        onToggleMessages: () => mounted && !_disposed ? setState(() => _showMessages = !_showMessages) : null,
        onToggleCamera: () {}, onToggleSettings: _navigateToSettings, onNewChat: _newChat,
        onQuickAction1: _quickAction1, onQuickAction2: _quickAction2, onQuickAction3: _quickAction3, onQuickAction4: _quickAction4,
        onToggleVoice: () => _speechService?.toggleDictation(), isMounted: () => mounted, isDisposed: () => _disposed, setState: (fn) => setState(fn),
      );
      _streamingTts.stop(); _tts.stop(); _tts = res.tts; _streamingTts = res.streamingTts;
      _chatHelpers = res.chatHelpers; _speechService = res.speechService; _keyboardHandler = res.keyboardHandler; _textRecognition = res.textRecognition;
      if (mounted && !_disposed) { setState(() => _initialising = false); _rootFocus.requestFocus(); _fadeController.forward(); }
    } catch (_) {
      if (mounted && !_disposed && !_redirectedOnError) { _redirectedOnError = true; Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ErrorRecoveryPage())); }
    }
  }

  @override void dispose() {
    _disposed = true; _scrollController.dispose(); _fadeController.dispose(); _streamingTts.stop(); _tts.stop();
    _speechService?.dispose(); _textRecognition?.dispose(); _rootFocus.dispose(); SemanticButtonRegistry.clear(); super.dispose();
  }

  Future<void> _newChat() async => _chatHelpers!.newChat(_msgs, _promptBarKey);
  Future<void> _quickAction1() => _chatHelpers!.quickAction1(_msgs); Future<void> _quickAction2() => _chatHelpers!.quickAction2(_msgs);
  Future<void> _quickAction3() => _chatHelpers!.quickAction3(_msgs); Future<void> _quickAction4() => _chatHelpers!.quickAction4(_msgs);

  Future<void> _navigateToSettings() async {
    if (_disposed || !mounted) return;
    final res = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => SettingsPage(systemContext: _systemCtx, backend: _backend)));
    if (res != null && mounted && !_disposed) {
      final newCtx = res['systemContext'] as String?, newBackend = res['backend'] as PreferredBackend?;
      if (newCtx != null && newBackend != null) setState(() {
        _systemCtx = newCtx; _chatHelpers!.updateSystemContext(_systemCtx);
        if (_backend != newBackend) { _backend = newBackend; _msgs.clear(); _initialising = true; BootstrapManager.reset(); _redirectedOnError = false; _bootstrap(); }
      });
    }
  }

  @override Widget build(BuildContext context) {
    if (_initialising) return ChatUIBuilder.buildLoadingScreen();
    return Shortcuts(shortcuts: _keyboardHandler!.shortcuts, child: Actions(actions: _keyboardHandler!.actions, child: Focus(
      focusNode: _rootFocus, autofocus: true, onKeyEvent: _speechService!.handleFocusKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: ChatUIBuilder.buildCleanAppBar(onNewChat: _newChat, onToggleSettings: _navigateToSettings, isResetting: _chatHelpers!.resetting),
        body: FadeTransition(opacity: _fadeAnimation, child: Column(children: [
          ChatUIBuilder.buildViewToggleButtons(showMessages: _showMessages, onToggleMessages: () => setState(() => _showMessages = !_showMessages), onNewChat: _newChat, isResetting: _chatHelpers!.resetting),
          if (_showMessages) ChatUIBuilder.buildMessagesContainer(_msgs, _scrollController) else const Expanded(child: SizedBox()),
          ChatUIBuilder.buildPromptBarContainer(
            promptBarKey: _promptBarKey, onPromptWithPhoto: (p) => _chatHelpers!.captureAndSend(p, _msgs), onPromptTextOnly: (p) => _chatHelpers!.sendTextOnly(p, _msgs),
            disabled: _chatHelpers!.resetting || _chatHelpers!.isGenerating, speechEnabled: _speechService!.speechEnabled, listening: _speechService!.listening,
            onToggleListening: _speechService!.toggleDictation, isGenerating: _chatHelpers!.isGenerating, isSpeaking: _chatHelpers!.isSpeaking, onStopTts: _speechService!.stopTts),
        ])),
      ),
    )));
  }
}
