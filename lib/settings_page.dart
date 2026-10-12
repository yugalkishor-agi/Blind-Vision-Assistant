// settings_page.dart
// ── BRUTALIST EDITORIAL DESIGN ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:io';
import 'chat_page/widgets/semantic_material_button.dart';
import 'chat_page/widgets/semantic_button_registry.dart';

const _sCream   = Color(0xFFF5F0E8);
const _sInk     = Color(0xFF1A1A1A);
const _sInkSoft = Color(0xFF3A3530);
const _sInkMute = Color(0xFF888070);
const _sAccent  = Color(0xFFE8441A);
const _sPaper   = Color(0xFFEDE8DF);
const _sBorderW = 2.0;

class SettingsPage extends StatefulWidget {
  final String systemContext;
  final PreferredBackend backend;
  final bool useRemoteModel;
  final String remoteUrl;
  const SettingsPage({
    Key? key,
    required this.systemContext,
    required this.backend,
    this.useRemoteModel = false,
    this.remoteUrl = '',
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _sysCtrl;
  late TextEditingController _remoteUrlCtrl;
  late PreferredBackend _selectedBackend;
  late bool _useRemoteModel;
  bool _hasChanges = false;

  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  final FocusScopeNode _pageScope = FocusScopeNode(debugLabel: 'SettingsPageScope');

  @override
  void initState() {
    super.initState();
    _sysCtrl = TextEditingController(text: widget.systemContext);
    _remoteUrlCtrl = TextEditingController(text: widget.remoteUrl);
    _selectedBackend = widget.backend;
    _useRemoteModel = widget.useRemoteModel;
    _sysCtrl.addListener(_onChange);
    _remoteUrlCtrl.addListener(_onChange);
  }

  @override
  void dispose() {
    _sysCtrl.removeListener(_onChange);
    _remoteUrlCtrl.removeListener(_onChange);
    _sysCtrl.dispose();
    _remoteUrlCtrl.dispose();
    _pageScope.dispose();
    SemanticButtonRegistry.clear();
    super.dispose();
  }

  void _onChange() {
    setState(() {
      _hasChanges =
          _sysCtrl.text.trim() != widget.systemContext.trim() ||
          _selectedBackend != widget.backend ||
          _useRemoteModel != widget.useRemoteModel ||
          _remoteUrlCtrl.text.trim() != widget.remoteUrl.trim();
    });
  }

  void _onBackendChanged(PreferredBackend? b) {
    if (b == null) return;
    setState(() {
      _selectedBackend = b;
      _hasChanges =
          _sysCtrl.text.trim() != widget.systemContext.trim() ||
          _selectedBackend != widget.backend ||
          _useRemoteModel != widget.useRemoteModel ||
          _remoteUrlCtrl.text.trim() != widget.remoteUrl.trim();
    });
  }

  void _save() => Navigator.of(context).pop({
    'systemContext': _sysCtrl.text.trim(),
    'backend': _selectedBackend,
    'useRemoteModel': _useRemoteModel,
    'remoteUrl': _remoteUrlCtrl.text.trim(),
  });
  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.arrowDown):  const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp):    const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowLeft):  const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.tab):        const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.enter):  const ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
    };
    if (_isIOS) {
      shortcuts[LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.alt,
        LogicalKeyboardKey.space,
      )] = const ActivateIntent();
    }

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            SemanticButtonRegistry.invokeCurrentSemanticTap();
            return null;
          }),
        },
        child: FocusScope(
          node: _pageScope,
          child: Scaffold(
            backgroundColor: _sCream,
            appBar: _buildAppBar(),
            body: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTip(),
                    const SizedBox(height: 28),
                    _sectionHead('System Context', 'GUIDES ALL AI RESPONSES'),
                    const SizedBox(height: 12),
                    Focus(child: _buildContextField()),
                    const SizedBox(height: 32),
                    _sectionHead('Controller Layout', 'BUTTON ASSIGNMENTS'),
                    const SizedBox(height: 14),
                    _buildShortcutsTable(),
                    const SizedBox(height: 32),
                    _buildControllerSetup(),
                    const SizedBox(height: 32),
                    _buildBackendSelector(),
                    const SizedBox(height: 32),
                    _buildRemoteModelSection(),
                    const SizedBox(height: 36),
                    _buildActionRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _sCream,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: Focus(
        autofocus: true,
        child: SemanticMaterialButton(
          label: 'Back',
          hint: 'Double-tap to return to chat',
          onPressed: _cancel,
          child: const Icon(Icons.arrow_back_ios_rounded, color: _sInk, size: 20),
        ),
      ),
      title: Semantics(
        header: true,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SETTINGS', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w900,
              color: _sInk, letterSpacing: 2.0,
            )),
            Text('CONFIGURE', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w900,
              color: _sAccent, letterSpacing: 2.0,
            )),
          ],
        ),
      ),
      actions: [
        if (_hasChanges)
          SemanticMaterialButton(
            label: 'Save',
            hint: 'Double-tap to save changes and return to chat',
            onPressed: _save,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: _sAccent,
                border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
                boxShadow: [BoxShadow(color: _sInk, offset: Offset(2, 2), blurRadius: 0)],
              ),
              child: const Text('SAVE', style: TextStyle(
                color: _sCream, fontSize: 10,
                fontWeight: FontWeight.w900, letterSpacing: 1.5,
                fontFamily: 'monospace',
              )),
            ),
          )
        else
          const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(height: 2, color: _sInk),
      ),
    );
  }

  Widget _buildTip() {
    final platform = _isIOS ? 'iOS VoiceOver'
        : _isAndroid ? 'Android TalkBack'
        : 'your screen reader';
    return Semantics(
      label: 'Tip: Temporarily turn off $platform when using a controller.',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: _sPaper,
          border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
          boxShadow: [BoxShadow(color: _sInk, offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              color: _sAccent,
              child: const Icon(Icons.lightbulb_outline_rounded, color: _sCream, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'For best results, temporarily turn off $platform when using a physical controller.',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: _sInkSoft, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHead(String title, String eyebrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: const TextStyle(
          fontSize: 9, fontFamily: 'monospace',
          color: _sAccent, fontWeight: FontWeight.w700, letterSpacing: 1.2,
        )),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: _sInk, letterSpacing: -0.5,
        )),
        const SizedBox(height: 6),
        Container(height: 2, width: 28, color: _sAccent),
      ],
    );
  }

  Widget _buildContextField() {
    return Semantics(
      label: 'System context text field',
      textField: true,
      child: Container(
        decoration: const BoxDecoration(
          color: _sPaper,
          border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
          boxShadow: [BoxShadow(color: _sInk, offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: TextField(
          controller: _sysCtrl,
          maxLines: 5,
          style: const TextStyle(color: _sInk, fontSize: 13, height: 1.6, fontFamily: 'monospace'),
          cursorColor: _sAccent,
          decoration: const InputDecoration(
            hintText: 'Enter system context for AI responses…',
            hintStyle: TextStyle(color: _sInkMute, fontSize: 13, fontFamily: 'monospace'),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.all(14),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutsTable() {
    const data = [
      ('Right Bumper', 'F1', 'Send with photo'),
      ('Large Right Trigger', 'F2', 'Toggle voice input'),
      ('Plus button (centre top right)', 'F3', 'New chat'),
      ('X top round button', 'F4', 'What is this?'),
      ('A right round button', 'F5', 'Describe room'),
      ('Y left round button', 'F6', 'Read text'),
      ('B bottom round button', 'F7', 'Tell me what you see'),
      ('Heart button (centre bottom right)', 'F8', 'Toggle settings'),
      ('Small Left Bumper', 'F9', 'Send text only'),
      ('Star button (centre bottom left)', 'F10', 'Toggle show messages'),
      ('Minus button (centre top left)', 'Enter', 'Activate button'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
        boxShadow: [BoxShadow(color: _sInk, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            color: _sInk,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('BUTTON', style: TextStyle(color: _sCream, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontFamily: 'monospace'))),
                Expanded(flex: 1, child: Text('KEY', style: TextStyle(color: _sAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontFamily: 'monospace'))),
                Expanded(flex: 3, child: Text('ACTION', style: TextStyle(color: _sCream, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontFamily: 'monospace'))),
              ],
            ),
          ),
          for (int i = 0; i < data.length; i++)
            Focus(
              child: Semantics(
                label: '${data[i].$1}, key ${data[i].$2}, action: ${data[i].$3}',
                child: Container(
                  color: i.isEven ? _sCream : _sPaper,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: Text(data[i].$1, style: const TextStyle(fontSize: 12, color: _sInkSoft, height: 1.4))),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: _sAccent,
                          child: Text(data[i].$2, style: const TextStyle(fontSize: 9, color: _sCream, fontWeight: FontWeight.w900, fontFamily: 'monospace'), textAlign: TextAlign.center),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(data[i].$3, style: const TextStyle(fontSize: 12, color: _sInk, fontWeight: FontWeight.w600, height: 1.4)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControllerSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHead('Controller Setup', 'FOR SIGHTED HELPERS'),
        const SizedBox(height: 12),
        Semantics(
          label: 'Controller layout image for sighted helper reference.',
          image: true,
          child: Container(
            height: 180, width: double.infinity,
            decoration: const BoxDecoration(
              color: _sPaper,
              border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
              boxShadow: [BoxShadow(color: _sInk, offset: Offset(3, 3), blurRadius: 0)],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/controller_setup.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    color: _sInk,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: const Text(
                      'CONTROLLER LAYOUT — sighted helper reference',
                      style: TextStyle(fontSize: 9, color: _sCream, fontWeight: FontWeight.w700, fontFamily: 'monospace', letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackendSelector() {
    return Semantics(
      label: 'Processing backend selector',
      child: Container(
        decoration: const BoxDecoration(
          color: _sPaper,
          border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
          boxShadow: [BoxShadow(color: _sInk, offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: _sInk,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: const Text('PROCESSING BACKEND', style: TextStyle(
                fontSize: 9, color: _sCream,
                fontWeight: FontWeight.w900, letterSpacing: 1.5, fontFamily: 'monospace',
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose how the model processes data.',
                      style: TextStyle(fontSize: 12, color: _sInkSoft, fontFamily: 'monospace', height: 1.5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildBackendToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendToggle() {
    return Container(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _backendOpt(PreferredBackend.cpu, 'CPU'),
          Container(width: _sBorderW, color: _sInk),
          _backendOpt(PreferredBackend.gpu, 'GPU'),
        ],
      ),
    );
  }

  Widget _backendOpt(PreferredBackend b, String lbl) {
    final selected = _selectedBackend == b;
    return SemanticMaterialButton(
      label: '$lbl backend',
      hint: 'Double-tap to select ${lbl.toLowerCase()} processing${selected ? ', currently selected' : ''}',
      onPressed: () => _onBackendChanged(b),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        color: selected ? _sAccent : _sCream,
        child: Text(lbl, style: TextStyle(
          color: selected ? _sCream : _sInk,
          fontWeight: FontWeight.w900, fontSize: 12,
          fontFamily: 'monospace', letterSpacing: 0.8,
        )),
      ),
    );
  }

  // ── Remote model section (dev/testing) ────────────────────────────────────
  Widget _buildRemoteModelSection() {
    return Container(
      decoration: const BoxDecoration(
        color: _sPaper,
        border: Border.fromBorderSide(BorderSide(color: _sInk, width: _sBorderW)),
        boxShadow: [BoxShadow(color: _sInk, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with toggle
          Container(
            width: double.infinity,
            color: _sInk,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'REMOTE MODEL  (DEV / TESTING)',
                    style: TextStyle(
                      fontSize: 9, color: _sCream,
                      fontWeight: FontWeight.w900, letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                // Toggle switch
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _useRemoteModel = !_useRemoteModel;
                      _onChange();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _useRemoteModel ? _sAccent : const Color(0xFF555050),
                      border: Border.all(color: _sCream, width: 1.5),
                    ),
                    child: Align(
                      alignment: _useRemoteModel
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18, height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: _sCream,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useRemoteModel
                      ? 'ON — app will call your Ollama server instead of the on-device model.'
                      : 'OFF — using on-device Gemma model (production mode).',
                  style: const TextStyle(
                    fontSize: 12, color: _sInkSoft,
                    fontFamily: 'monospace', height: 1.5,
                  ),
                ),

                if (_useRemoteModel) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'OLLAMA URL',
                    style: TextStyle(
                      fontSize: 9, color: _sAccent,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label: 'Remote model URL text field',
                    textField: true,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _sCream,
                        border: Border.fromBorderSide(
                            BorderSide(color: _sInk, width: _sBorderW)),
                      ),
                      child: TextField(
                        controller: _remoteUrlCtrl,
                        style: const TextStyle(
                          color: _sInk, fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        cursorColor: _sAccent,
                        autocorrect: false,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText:
                              'https://xxxx.trycloudflare.com',
                          hintStyle: TextStyle(
                            color: _sInkMute, fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'App calls  <URL>/v1/chat/completions  (Ollama OpenAI-compatible)',
                    style: TextStyle(
                      fontSize: 9, color: _sInkMute,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(child: _actionBtn('CANCEL', 'Double-tap to cancel', _cancel, isAccent: false)),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            'SAVE CHANGES',
            _hasChanges ? 'Double-tap to save changes' : 'No changes to save',
            _hasChanges ? _save : null,
            isAccent: true,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String lbl, String hint, VoidCallback? onTap, {required bool isAccent}) {
    final enabled = onTap != null;
    final bg = enabled ? (isAccent ? _sAccent : _sInk) : const Color(0xFFCCC8BE);
    final fg = enabled ? _sCream : _sInkMute;

    if (!enabled) {
      return Container(
        height: 50,
        decoration: const BoxDecoration(color: Color(0xFFCCC8BE)),
        child: Center(child: Text(lbl, style: const TextStyle(color: _sInkMute, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontFamily: 'monospace'))),
      );
    }

    return SemanticMaterialButton(
      label: lbl, hint: hint, onPressed: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: _sInk, width: _sBorderW),
            boxShadow: const [BoxShadow(color: _sInk, offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: Center(
            child: Text(lbl, style: TextStyle(
              color: fg, fontSize: 11,
              fontWeight: FontWeight.w900, letterSpacing: 1.2,
              fontFamily: 'monospace',
            )),
          ),
        ),
      ),
    );
  }
}
