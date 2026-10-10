import 'package:flutter/material.dart';
import 'config/constants.dart';
import 'logic/download_logic.dart';
import 'models/enums.dart';
import 'models/models.dart';
import 'services/download_manager.dart';
import 'ui/ui_helpers.dart';
import '../chat_page/gemma_vision_chat.dart';

class ModelDownloadPage extends StatefulWidget {
  const ModelDownloadPage({Key? key}) : super(key: key);

  @override
  State<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends State<ModelDownloadPage> {
  late DownloadManager _downloadManager;
  late DownloadLogic _downloadLogic;
  DownloadState _state = const DownloadState();

  @override
  void initState() {
    super.initState();
    _downloadManager = DownloadManager();
    _downloadManager.initialize().then((_) {
      _downloadLogic = DownloadLogic(manager: _downloadManager, context: context);
      _downloadLogic.stateStream.listen((state) {
        if (mounted) {
          setState(() => _state = state);
          if (state.status == DownloadStatus.completed) _navigateToChat();
        }
      });
      setState(() => _state = _downloadManager.currentState);
      _downloadLogic.isModelInstalled().then((installed) {
        if (installed && mounted) _navigateToChat();
      });
    });
  }

  void _navigateToChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  @override
  void dispose() {
    _downloadManager.dispose();
    super.dispose();
  }

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
              const Icon(Icons.visibility, size: 64, color: Color(0xFF4A90D9)),
              const SizedBox(height: 16),
              const Text('Blind Vision Assistant',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(modelFullName,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 32),
              DownloadUIHelpers.buildProgressSection(_state.status, _state.progress),
              const SizedBox(height: 24),
              DownloadUIHelpers.buildActionButton(
                status: _state.status,
                onStart: _downloadLogic.startOrResumeDownload,
                onPause: _downloadLogic.pauseDownload,
                onResume: _downloadLogic.startOrResumeDownload,
                onCancel: _downloadLogic.cancelDownload,
              ),
              if (_state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_state.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
