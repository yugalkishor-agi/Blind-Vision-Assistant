// settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:io';
import 'chat_page/widgets/semantic_material_button.dart';
import 'chat_page/widgets/semantic_button_registry.dart';

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

  /// Platform detection for accessibility-specific features
  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// Page-wide focus scope for comprehensive keyboard navigation
  final FocusScopeNode _pageScope = FocusScopeNode(
    debugLabel: 'SettingsPageScope',
  );

  @override
  void initState() {
    super.initState();
    _systemContextController = TextEditingController(
      text: widget.systemContext,
    );
    _selectedBackend = widget.backend;
    _systemContextController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _systemContextController.removeListener(_onTextChanged);
    _systemContextController.dispose();
    _pageScope.dispose();
    SemanticButtonRegistry.clear(); // Clean up accessibility state
    super.dispose();
  }

  /// Track changes to enable/disable save button and show unsaved changes indicator
  void _onTextChanged() {
    setState(() {
      _hasChanges =
          _systemContextController.text.trim() != widget.systemContext.trim() ||
          _selectedBackend != widget.backend;
    });
  }

  /// Handle backend selection with change tracking
  void _onBackendChanged(PreferredBackend? backend) {
    if (backend != null) {
      setState(() {
        _selectedBackend = backend;
        _hasChanges =
            _systemContextController.text.trim() !=
                widget.systemContext.trim() ||
            _selectedBackend != widget.backend;
      });
    }
  }

  /// Save changes and return to chat page
  void _save() => Navigator.of(context).pop({
    'systemContext': _systemContextController.text.trim(),
    'backend': _selectedBackend,
  });

  /// Cancel changes and return to chat page
  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    // Comprehensive keyboard shortcut mapping for accessibility
    final shortcuts = <LogicalKeySet, Intent>{
      // Arrow key navigation for screen readers and keyboard users
      LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift):
          const PreviousFocusIntent(),

      // Universal activation keys
      LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
    };

    // iOS VoiceOver specific activation combination
    if (_isIOS) {
      shortcuts[LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.space,
          )] =
          const ActivateIntent();
    }

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          // Handle activation intents through semantic button registry
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
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              leading: Focus(
                autofocus: true, // Initial focus for screen readers
                child: SemanticMaterialButton(
                  label: 'Back',
                  hint: 'Double-tap to return to chat',
                  onPressed: _cancel,
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.blue,
                    semanticLabel: 'Back to chat',
                  ),
                ),
              ),
              title: Semantics(
                header: true, // Mark as heading for screen readers
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              actions: [
                // Conditional save button when changes exist
                if (_hasChanges)
                  SemanticMaterialButton(
                    label: 'Save',
                    hint: 'Double-tap to save changes and return to chat',
                    onPressed: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
              ],
            ),
            body: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(), // Predictable tab order
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _wrapFocus(_buildAccessibilityAdvice()),
                    const SizedBox(height: 32),
                    _wrapFocus(
                      _buildSectionHeader(
                        'System Context',
                        'This context guides all AI responses',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _wrapFocus(_buildContextField()),
                    const SizedBox(height: 40),
                    _wrapFocus(
                      _buildSectionHeader(
                        'Controller Layout',
                        'Button assignments for your controller',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildShortcutsTable(),
                    const SizedBox(height: 40),
                    _wrapFocus(_buildControllerSetup()),
                    const SizedBox(height: 40),
                    _wrapFocus(_buildBackendSelector()),
                    const SizedBox(height: 40),
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

  /// Make any widget keyboard-focusable for comprehensive navigation
  Widget _wrapFocus(Widget child) => Focus(child: child);

  /// Platform-specific accessibility advice for controller users
  Widget _buildAccessibilityAdvice() {
    final platform = _isIOS
        ? 'iOS VoiceOver'
        : _isAndroid
        ? 'Android TalkBack'
        : 'your screen reader';
    return Semantics(
      label:
          'Controller tip: For best experience, temporarily turn off $platform when using a controller.',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'For best experience, temporarily turn off $platform when using a controller.',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable section header with semantic heading markup
  Widget _buildSectionHeader(String title, String desc) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true, // Screen reader heading navigation
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
    ],
  );

  /// Multi-line text field for system context editing
  Widget _buildContextField() => Semantics(
    label: 'System context text field',
    textField: true,
    child: Container(
      decoration: _boxDecoration(),
      child: TextField(
        controller: _systemContextController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Enter system context for AI responses...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    ),
  );

  /// Consistent box decoration for containers
  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade300),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Comprehensive controller mapping table with detailed button descriptions
  Widget _buildShortcutsTable() {
    // Complete controller mapping for blind users
    const data = [
      ('Right Bumper', 'F1', 'Send with photo'),
      ('Large Right Trigger', 'F2', 'Toggle voice input'),
      (
        'Plus button (the small flat button in the centre top right)',
        'F3',
        'New chat',
      ),
      ('X top round button', 'F4', 'What is this?'),
      ('A right round button', 'F5', 'Describe room'),
      ('Y left round button', 'F6', 'Read text'),
      ('B bottom round button', 'F7', 'Tell me what you see'),
      (
        'Heart button (the small flat button in the centre bottom right)',
        'F8',
        'Toggle settings',
      ),
      ('Small Left Bumper', 'F9', 'Send text only'),
      (
        'Star button (the small flat button in the centre bottom left)',
        'F10',
        'Toggle show messages',
      ),
      (
        'Minus button (the small flat button in the centre top left)',
        'Enter',
        'Activate button',
      ),
    ];

    /// Create table row with proper styling
    Widget row(String a, String b, String c, {bool header = false}) {
      final styleH = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Colors.grey.shade900,
      );
      final styleA = TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      );
      final styleB = const TextStyle(
        fontSize: 14,
        fontFamily: 'monospace', // Monospace for key names
        fontWeight: FontWeight.bold,
      );
      final styleC = TextStyle(fontSize: 14, color: Colors.grey.shade700);

      Widget cell(String t, TextStyle s, {bool key = false}) => Expanded(
        flex: key ? 1 : 3, // Narrow column for key names
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(t, style: s),
        ),
      );

      final r = Row(
        children: [
          cell(a, header ? styleH : styleA),
          cell(b, header ? styleH : styleB, key: true),
          cell(c, header ? styleH : styleC),
        ],
      );

      return header
          ? Container(color: Colors.grey.shade300.withOpacity(.4), child: r)
          : Focus(
              child: Semantics(
                label: '$a, key $b, action: $c',
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: r,
                ),
              ),
            );
    }

    return Column(
      children: [
        row('Button', 'Key', 'Action', header: true),
        for (final s in data) row(s.$1, s.$2, s.$3),
      ],
    );
  }

  /// Controller setup image with accessibility description
  Widget _buildControllerSetup() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(
        'Controller Setup',
        'If a sighted person is available, they can follow this picture to help set up your controller. You don\'t have to, but it can make things easier.',
      ),
      const SizedBox(height: 16),
      Semantics(
        label:
            'Image showing the physical controller layout. A sighted helper can refer to it during setup.',
        image: true,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: _boxDecoration(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/controller_setup.png', fit: BoxFit.cover),
                Text(
                  'Photo of controller layout',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  /// Backend selector (CPU vs GPU) with toggle interface
  Widget _buildBackendSelector() => Semantics(
    label: 'Processing backend selector',
    child: Container(
      decoration: _boxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing Backend',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose processing method',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildBackendToggle(),
        ],
      ),
    ),
  );

  /// Toggle switch for backend selection
  Widget _buildBackendToggle() => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _backendOption(PreferredBackend.cpu, 'CPU', Icons.memory_rounded),
        _backendOption(
          PreferredBackend.gpu,
          'GPU',
          Icons.developer_board_rounded,
        ),
      ],
    ),
  );

  /// Individual backend option with selection state
  Widget _backendOption(PreferredBackend b, String lbl, IconData icn) {
    final selected = _selectedBackend == b;
    return SemanticMaterialButton(
      label: '$lbl backend',
      hint:
          'Double-tap to select ${lbl.toLowerCase()} processing${selected ? ', currently selected' : ''}',
      onPressed: () => _onBackendChanged(b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icn,
              size: 18,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              lbl,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom action buttons (Cancel/Save) with state-aware styling
  Widget _buildActionRow() => Row(
    children: [
      Expanded(
        child: _actionBtn(
          'Cancel',
          'Double-tap to cancel changes and return to chat',
          _cancel,
          primary: false,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _actionBtn(
          'Save Changes',
          _hasChanges
              ? 'Double-tap to save changes and return to chat'
              : 'No changes to save',
          _hasChanges ? _save : null,
          primary: true,
          enabled: _hasChanges,
        ),
      ),
    ],
  );

  /// Reusable action button with enabled/disabled states
  Widget _actionBtn(
    String lbl,
    String hint,
    VoidCallback? onTap, {
    required bool primary,
    bool enabled = true,
  }) {
    // Disabled button styling
    if (!enabled || onTap == null) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            lbl,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return SemanticMaterialButton(
      label: lbl,
      hint: hint,
      onPressed: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                )
              : null,
          color: primary ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: primary
                  ? Colors.green.withOpacity(.2)
                  : Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            lbl,
            style: TextStyle(
              color: primary ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
