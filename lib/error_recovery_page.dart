import 'package:flutter/material.dart';

class ErrorRecoveryPage extends StatelessWidget {
  const ErrorRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load AI model',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'The Gemma model could not be initialized. Please re-download the model.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              Semantics(
                label: 'Go back to download page',
                button: true,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.download),
                  label: const Text('Re-download Model'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
