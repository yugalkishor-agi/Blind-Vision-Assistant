import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../services/download_manager.dart';
import '../services/huggingface_oauth.dart';
import '../services/token_manager.dart';
import '../services/logger.dart';

class DownloadLogic {
  final DownloadManager _manager;
  final BuildContext _context;

  DownloadLogic({required DownloadManager manager, required BuildContext context})
      : _manager = manager,
        _context = context;

  Stream<DownloadState> get stateStream => _manager.stateStream;
  DownloadState get currentState => _manager.currentState;

  Future<bool> isModelInstalled() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/gemma-3n-E2B-it-int4.task');
    return file.existsSync() && file.lengthSync() > 100 * 1024 * 1024;
  }

  Future<void> startOrResumeDownload() async {
    final installed = await isModelInstalled();
    if (installed) { _navigateToChat(); return; }

    final state = _manager.currentState;
    if (state.status == DownloadStatus.paused) {
      await _manager.resumeDownload(); return;
    }

    String? token = await TokenManager.getToken();
    if (token == null) {
      final hfToken = await HuggingFaceOAuth.authenticate();
      if (hfToken == null) { _showError('Authentication failed'); return; }
      await TokenManager.saveToken(hfToken);
      token = hfToken.accessToken;
    }
    await _manager.startDownload(token);
  }

  Future<void> pauseDownload() async => _manager.pauseDownload();
  Future<void> cancelDownload() async => _manager.cancelDownload();

  void checkAndNavigate(DownloadState state) {
    if (state.status == DownloadStatus.completed) _navigateToChat();
  }

  void _navigateToChat() {
    if (_context.mounted) {
      Navigator.of(_context).pushReplacementNamed('/chat');
    }
  }

  void _showError(String message) {
    if (_context.mounted) {
      ScaffoldMessenger.of(_context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
