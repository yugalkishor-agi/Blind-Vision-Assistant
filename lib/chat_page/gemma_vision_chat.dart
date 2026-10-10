//chat_page/gemma_vision_chat.dart

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
import '/error_recovery_page.dart';
import 'handlers/keyboard_handler.dart';
import 'widgets/chat_ui_builder.dart';
import '../settings_page.dart';
import 'widgets/semantic_button_registry.dart';
import 'config/system_prompts.dart';

/// Main chat interface with AI vision model - handles bootstrap and lifecycle management
class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  /* Core state */
  /// Chat message history
  final _msgs = <ChatMessage>[];

  /// UI toggle states
  bool _showMessages = false;
  bool _showCamera = true;

  /// TTS services (initially temporary, replaced after bootstrap)
  late FlutterTts _tts = FlutterTts();
  late StreamingTtsService _streamingTts = StreamingTtsService(_tts);

  /// Service references (nullable until bootstrap completes)
  ChatHelpers? _chatHelpers;
  SpeechService? _speechService;
  KeyboardHandler? _keyboardHandler;
  TextRecognitionService? _textRecognition;

  /// AI model configuration
  String _systemCtx = SystemPrompts.blindUserNavigation;
  PreferredBackend _backend = PreferredBackend.cpu;

  /* UI control */
  final _promptBarKey = GlobalKey<PromptBarState>();
  bool _initialising = true;
  bool _redirectedOnError = false; // Prevents duplicate error handling
  bool _disposed = false; // Lifecycle guard

  /* Focus management for accessibility */
  final FocusNode _rootFocus = FocusNode();

  /* Auto-scroll for message list */
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  /* Page transition animations */
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _bootstrap(); // Start service initialization
  }

  /// Setup smooth page entry animations
  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  /// Service initialization with crash recovery and lifecycle guards
  Future<void> _bootstrap() async {
    if (_disposed) return;

    try {
      // BootstrapManager handles heavy lifting: TTS, AI model, speech, camera, etc.
      final result = await BootstrapManager.bootstrap(
        context: context,
        systemContext: _systemCtx,
        backend: _backend,
        promptBarKey: _promptBarKey,
        // Callback functions with lifecycle safety checks
        onToggleMessages: () {
          if (mounted && !_disposed) {
            setState(() => _showMessages = !_showMessages);
            if (_showMessages) {
              _scrollToBottom(force: true);
            }
          }
        },
        onToggleCamera: () {
          if (mounted && !_disposed) setState(() => _showCamera = !_showCamera);
        },
        onToggleSettings: _navigateToSettings,
        onNewChat: _newChat,
        onQuickAction1: _quickAction1,
        onQuickAction2: _quickAction2,
        onQuickAction3: _quickAction3,
        onQuickAction4: _quickAction4,
        onToggleVoice: () {
          _speechService?.toggleDictation(); // F2 key handler
        },
        // Lifecycle callbacks for bootstrap safety
        isMounted: () => mounted,
        isDisposed: () => _disposed,
        setState: (fn) {
          setState(fn);
          if (_showMessages) {
            _scheduleAutoScroll(); // Auto-scroll when messages update
          }
        },
      );

      // Clean up temporary services before replacing with bootstrap results
      _streamingTts.stop();
      _tts.stop();

      // Store bootstrap results
      _tts = result.tts;
      _streamingTts = result.streamingTts;
      _chatHelpers = result.chatHelpers;
      _speechService = result.speechService;
      _keyboardHandler = result.keyboardHandler;
      _textRecognition = result.textRecognition;

      if (mounted && !_disposed) {
        setState(() => _initialising = false);
        _rootFocus.requestFocus(); // Focus for keyboard shortcuts
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      // Handle bootstrap failures directly - navigate to error recovery page
      debugPrint("Gemma service initialization failed: $e");

      if (mounted && !_disposed && !_redirectedOnError) {
        _redirectedOnError = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ErrorRecoveryPage()),
        );
      }
    }
  }

  /* Auto-scroll to keep latest messages visible */

  /// Debounced scroll scheduling to avoid excessive scrolling
  void _scheduleAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  /// Scroll to bottom with safety checks
  void _scrollToBottom({bool force = false}) {
    if (!_showMessages && !force) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true; // Set flag first to prevent async operations
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _streamingTts.stop();
    _tts.stop();
    _speechService?.dispose();
    _textRecognition?.dispose();
    _rootFocus.dispose();
    SemanticButtonRegistry.clear(); // Clean up accessibility registry
    super.dispose();
  }

  /* Chat operation wrappers with null safety */
  Future<void> _newChat() async =>
      await _chatHelpers!.newChat(_msgs, _promptBarKey);

  Future<void> _captureAndSend(String prompt) async =>
      await _chatHelpers!.captureAndSend(prompt, _msgs);

  Future<void> _sendTextOnly(String prompt) async =>
      await _chatHelpers!.sendTextOnly(prompt, _msgs);

  /* Quick action shortcuts for common vision tasks */
  Future<void> _quickAction1() async => _chatHelpers!.quickAction1(_msgs);
  Future<void> _quickAction2() async => _chatHelpers!.quickAction2(_msgs);
  Future<void> _quickAction3() async => _chatHelpers!.quickAction3(_msgs);
  Future<void> _quickAction4() async => _chatHelpers!.quickAction4(_msgs);

  @override
  Widget build(BuildContext context) {
    if (_initialising) return ChatUIBuilder.buildLoadingScreen();
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    /// Keyboard shortcut system with cross-platform accessibility support
    return Shortcuts(
      shortcuts: _keyboardHandler!.shortcuts,
      child: Actions(
        actions: _keyboardHandler!.actions,
        child: Focus(
          focusNode: _rootFocus,
          autofocus: true,
          onKeyEvent: _speechService!.handleFocusKey, // Speech integration
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: ChatUIBuilder.buildCleanAppBar(
              onNewChat: _newChat,
              onToggleSettings: _navigateToSettings,
              isResetting: _chatHelpers!.resetting,
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    /* View toggle buttons */
                    ChatUIBuilder.buildViewToggleButtons(
                      showMessages: _showMessages,
                      onToggleMessages: () {
                        setState(() => _showMessages = !_showMessages);
                        if (_showMessages) {
                          _scrollToBottom(force: true);
                        }
                      },
                      onNewChat: _newChat,
                      isResetting: _chatHelpers!.resetting,
                    ),

                    /* Expandable message list or spacer */
                    if (_showMessages)
                      ChatUIBuilder.buildMessagesContainer(
                        _msgs,
                        _scrollController,
                      )
                    else
                      const Expanded(child: SizedBox()),

                    /* Fixed prompt bar at bottom */
                    ChatUIBuilder.buildPromptBarContainer(
                      promptBarKey: _promptBarKey,
                      onPromptWithPhoto: _captureAndSend,
                      onPromptTextOnly: _sendTextOnly,
                      disabled:
                          _chatHelpers!.resetting || _chatHelpers!.isGenerating,
                      speechEnabled: _speechService!.speechEnabled,
                      listening: _speechService!.listening,
                      onToggleListening: _speechService!.toggleDictation,
                      isGenerating: _chatHelpers!.isGenerating,
                      isSpeaking: _chatHelpers!.isSpeaking,
                      onStopTts: _speechService!.stopTts,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Navigate to settings with backend switching support
  Future<void> _navigateToSettings() async {
    if (_disposed || !mounted) return;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) =>
            SettingsPage(systemContext: _systemCtx, backend: _backend),
      ),
    );

    // Process settings changes with full re-bootstrap if backend changed
    if (result != null && mounted && !_disposed) {
      final newSystemContext = result['systemContext'] as String?;
      final newBackend = result['backend'] as PreferredBackend?;

      if (newSystemContext != null && newBackend != null) {
        setState(() {
          _systemCtx = newSystemContext;
          _chatHelpers!.updateSystemContext(_systemCtx);

          // Backend change requires full re-initialization
          if (_backend != newBackend) {
            _backend = newBackend;
            _msgs.clear();
            _initialising = true;
            BootstrapManager.reset();
            _redirectedOnError = false;
            _bootstrap(); // Re-initialize with new backend
          }
        });
      }
    }
  }
}
