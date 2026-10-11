// settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:io';
import 'chat_page/widgets/semantic_material_button.dart';
import 'chat_page/widgets/semantic_button_registry.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0A0A14);
  static const surface   = Color(0xFF12121E);
  static const surface2  = Color(0xFF1A1A2E);
  static const border    = Color(0xFF2D2D3F);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF06B6D4);
  static const pink      = Color(0xFFEC4899);
  static const green     = Color(0xFF10B981);
  static const amber     = Color(0xFFF59E0B);
  static const textHi    = Color(0xFFF1F5F9);
  static const textMid   = Color(0xFF94A3B8);
  static const textLo    = Color(0xFF475569);
}
// ─────────────────────────────────────────────────────────────────────────────

/// Settings page for configuring AI system context, controller layout, and processing backend
/// Optimized for accessibility with comprehensive keyboard navigation and screen reader support
class SettingsPage extends StatefulWidget {
  final String systemContext;
  final PreferredBackend backend;

  const SettingsPage({
    Key? key,
    required this.systemContext,
    required this.backend,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _systemContextController;
  late PreferredBackend _selectedBackend;
  bool _hasChanges = false;

  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  final FocusScopeNode _pageScope = FocusScopeNode(debugLabel: 'SettingsPageScope');

  @override
  void initState() {
    super.initState();
    _systemContextController = TextEditingController(text: widget.systemContext);
    _selectedBackend = widget.backend;
    _systemContextController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _systemContextController.removeListener(_onTextChanged);
    _systemContextController.dispose();
    _pageScope.dispose();
    SemanticButtonRegistry.clear();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasChanges =
          _systemContextController.text.trim() != widget.systemContext.trim() ||
          _selectedBackend != widget.backend;
    });
  }

  void _onBackendChanged(PreferredBackend? backend) {
    if (backend != null) {
      setState(() {
        _selectedBackend = backend;
        _hasChanges =
            _systemContextController.text.trim() != widget.systemContext.trim() ||
            _selectedBackend != widget.backend;
      });
    }
  }

  void _save() => Navigator.of(context).pop({
    'systemContext': _systemContextController.text.trim(),
    'backend': _selectedBackend,
  });

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
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
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              SemanticButtonRegistry.invokeCurrentSemanticTap();
              return null;
            },
          ),
        },
        child: FocusScope(
          node: _pageScope,
          child: Scaffold(
            backgroundColor: _C.bg,
            appBar: _buildAppBar(),
            body: Stack(
              children: [
                // Ambient glow top
                Positioned(
                  top: -100,
                  right: -60,
                  child: _ambientBlob(_C.violet, 260),
                ),
                FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _wrapFocus(_buildAccessibilityAdvice()),
                        const SizedBox(height: 28),
                        _wrapFocus(_buildSectionHeader('System Context', 'Guides all AI responses')),
                        const SizedBox(height: 12),
                        _wrapFocus(_buildContextField()),
                        const SizedBox(height: 32),
                        _wrapFocus(_buildSectionHeader('Controller Layout', 'Button assignments for your controller')),
                        const SizedBox(height: 16),
                        _buildShortcutsTable(),
                        const SizedBox(height: 32),
                        _wrapFocus(_buildControllerSetup()),
                        const SizedBox(height: 32),
                        _wrapFocus(_buildBackendSelector()),
                        const SizedBox(height: 36),
                        _buildActionRow(),
                      ],
                    ),
                  ),
                ),
              ],
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
      backgroundColor: _C.bg,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Focus(
        autofocus: true,
        child: SemanticMaterialButton(
          label: 'Back',
          hint: 'Double-tap to return to chat',
          onPressed: _cancel,
          child: const Icon(Icons.arrow_back_ios_rounded, color: _C.textMid),
        ),
      ),
      title: Semantics(
        header: true,
        child: const Text(
          'Settings',
          style: TextStyle(color: _C.textHi, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.green, Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _C.green.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        if (!_hasChanges) const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  Widget _ambientBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.12), Colors.transparent],
        ),
      ),
    );
  }

  Widget _wrapFocus(Widget child) => Focus(child: child);

  // ── Accessibility advice card ──────────────────────────────────────────────
  Widget _buildAccessibilityAdvice() {
    final platform = _isIOS ? 'iOS VoiceOver' : _isAndroid ? 'Android TalkBack' : 'your screen reader';
    return Semantics(
      label: 'Controller tip: For best experience, temporarily turn off $platform when using a controller.',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _C.cyan.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.cyan.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _C.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded, color: _C.cyan, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'For best experience, temporarily turn off $platform when using a controller.',
                style: const TextStyle(color: _C.textMid, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: _C.textHi,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(desc, style: const TextStyle(color: _C.textLo, fontSize: 13)),
      ],
    );
  }

  // ── Context text field ─────────────────────────────────────────────────────
  Widget _buildContextField() {
    return Semantics(
      label: 'System context text field',
      textField: true,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: TextField(
          controller: _systemContextController,
          maxLines: 5,
          style: const TextStyle(color: _C.textHi, fontSize: 14, height: 1.5),
          cursorColor: _C.violet,
          decoration: const InputDecoration(
            hintText: 'Enter system context for AI responses…',
            hintStyle: TextStyle(color: _C.textLo, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(18),
          ),
        ),
      ),
    );
  }

  // ── Shortcuts table ────────────────────────────────────────────────────────
  Widget _buildShortcutsTable() {
    const data = [
      ('Right Bumper', 'F1', 'Send with photo'),
      ('Large Right Trigger', 'F2', 'Toggle voice input'),
      ('Plus button (small flat button centre top right)', 'F3', 'New chat'),
      ('X top round button', 'F4', 'What is this?'),
      ('A right round button', 'F5', 'Describe room'),
      ('Y left round button', 'F6', 'Read text'),
      ('B bottom round button', 'F7', 'Tell me what you see'),
      ('Heart button (small flat button centre bottom right)', 'F8', 'Toggle settings'),
      ('Small Left Bumper', 'F9', 'Send text only'),
      ('Star button (small flat button centre bottom left)', 'F10', 'Toggle show messages'),
      ('Minus button (small flat button centre top left)', 'Enter', 'Activate button'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header row
            Container(
              color: _C.surface2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Button', style: TextStyle(color: _C.textMid, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6))),
                  Expanded(flex: 1, child: Text('Key', style: TextStyle(color: _C.textMid, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6))),
                  Expanded(flex: 3, child: Text('Action', style: TextStyle(color: _C.textMid, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6))),
                ],
              ),
            ),
            // Data rows
            for (int i = 0; i < data.length; i++)
              Focus(
                child: Semantics(
                  label: '${data[i].$1}, key ${data[i].$2}, action: ${data[i].$3}',
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: i < data.length - 1 ? _C.border : Colors.transparent)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(data[i].$1, style: const TextStyle(color: _C.textMid, fontSize: 13, height: 1.4)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.violet.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _C.violet.withOpacity(0.3)),
                            ),
                            child: Text(
                              data[i].$2,
                              style: const TextStyle(
                                color: _C.violet,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(data[i].$3, style: const TextStyle(color: _C.textHi, fontSize: 13, height: 1.4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Controller setup ───────────────────────────────────────────────────────
  Widget _buildControllerSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Controller Setup',
          'A sighted person can use this image to help configure your controller.',
        ),
        const SizedBox(height: 14),
        Semantics(
          label: 'Image showing the physical controller layout. A sighted helper can refer to it during setup.',
          image: true,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/controller_setup.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  const Positioned(
                    bottom: 12,
                    child: Text(
                      'Controller Layout',
                      style: TextStyle(color: _C.textMid, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Backend selector ───────────────────────────────────────────────────────
  Widget _buildBackendSelector() {
    return Semantics(
      label: 'Processing backend selector',
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _C.violet.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.memory_rounded, color: _C.violet, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processing Backend',
                    style: TextStyle(color: _C.textHi, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text('Choose processing method', style: TextStyle(color: _C.textLo, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildBackendToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _backendOption(PreferredBackend.cpu, 'CPU', Icons.memory_rounded),
          _backendOption(PreferredBackend.gpu, 'GPU', Icons.developer_board_rounded),
        ],
      ),
    );
  }

  Widget _backendOption(PreferredBackend b, String lbl, IconData icn) {
    final selected = _selectedBackend == b;
    return SemanticMaterialButton(
      label: '$lbl backend',
      hint: 'Double-tap to select ${lbl.toLowerCase()} processing${selected ? ', currently selected' : ''}',
      onPressed: () => _onBackendChanged(b),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_C.violet, Color(0xFF5B21B6)])
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [BoxShadow(color: _C.violet.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          children: [
            Icon(icn, size: 15, color: selected ? Colors.white : _C.textLo),
            const SizedBox(width: 6),
            Text(
              lbl,
              style: TextStyle(
                color: selected ? Colors.white : _C.textMid,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action row ─────────────────────────────────────────────────────────────
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(child: _actionBtn('Cancel', 'Double-tap to cancel and return to chat', _cancel, primary: false)),
        const SizedBox(width: 14),
        Expanded(
          child: _actionBtn(
            'Save Changes',
            _hasChanges ? 'Double-tap to save changes and return to chat' : 'No changes to save',
            _hasChanges ? _save : null,
            primary: true,
            enabled: _hasChanges,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String lbl, String hint, VoidCallback? onTap, {required bool primary, bool enabled = true}) {
    if (!enabled || onTap == null) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Center(
          child: Text(lbl, style: const TextStyle(color: _C.textLo, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      );
    }
    return SemanticMaterialButton(
      label: lbl,
      hint: hint,
      onPressed: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(colors: [_C.green, Color(0xFF059669)])
              : null,
          color: primary ? null : _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary ? Colors.transparent : _C.border),
          boxShadow: primary
              ? [BoxShadow(color: _C.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Center(
          child: Text(
            lbl,
            style: TextStyle(
              color: primary ? Colors.white : _C.textMid,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
