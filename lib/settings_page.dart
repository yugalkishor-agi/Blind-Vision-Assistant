import 'package:flutter/material.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'chat_page/config/system_prompts.dart';

class SettingsPage extends StatefulWidget {
  final String systemContext;
  final PreferredBackend backend;
  const SettingsPage({super.key, required this.systemContext, required this.backend});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _promptController;
  late PreferredBackend _backend;

  @override void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.systemContext);
    _backend = widget.backend;
  }

  @override void dispose() { _promptController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF4A90D9),
        foregroundColor: Colors.white,
        actions: [
          Semantics(
            label: 'Save settings', button: true,
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => Navigator.of(context).pop({'systemContext': _promptController.text, 'backend': _backend}),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Prompt', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Semantics(
              label: 'System prompt editor',
              child: TextField(
                controller: _promptController, maxLines: 5,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Backend', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Semantics(
              label: 'CPU backend',
              child: RadioListTile<PreferredBackend>(
                title: const Text('CPU'), value: PreferredBackend.cpu, groupValue: _backend,
                onChanged: (v) => setState(() => _backend = v!),
              ),
            ),
            Semantics(
              label: 'GPU backend',
              child: RadioListTile<PreferredBackend>(
                title: const Text('GPU'), value: PreferredBackend.gpu, groupValue: _backend,
                onChanged: (v) => setState(() => _backend = v!),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Reset to default prompt', button: true,
              child: TextButton(
                onPressed: () => setState(() => _promptController.text = SystemPrompts.blindUserNavigation),
                child: const Text('Reset to Default'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
