import 'package:flutter/material.dart';
import '../models/enums.dart';

class DownloadUIHelpers {
  static String getStatusText(DownloadStatus status, int progress) {
    switch (status) {
      case DownloadStatus.notStarted: return 'Ready to download';
      case DownloadStatus.downloading: return 'Downloading... $progress%';
      case DownloadStatus.paused: return 'Paused at $progress%';
      case DownloadStatus.completed: return 'Download complete';
      case DownloadStatus.failed: return 'Download failed';
      case DownloadStatus.cancelled: return 'Download cancelled';
    }
  }

  static Color getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed: return Colors.green;
      case DownloadStatus.failed: return Colors.red;
      case DownloadStatus.downloading: return Colors.blue;
      case DownloadStatus.paused: return Colors.orange;
      default: return Colors.grey;
    }
  }

  static Widget buildProgressSection(DownloadStatus status, int progress) {
    final isRunning = status == DownloadStatus.downloading || status == DownloadStatus.paused;
    return Column(
      children: [
        Semantics(
          label: getStatusText(status, progress),
          child: LinearProgressIndicator(
            value: isRunning ? progress / 100.0 : null,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(getStatusColor(status)),
          ),
        ),
        const SizedBox(height: 8),
        Text(getStatusText(status, progress),
            style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.w500)),
      ],
    );
  }

  static Widget buildActionButton({
    required DownloadStatus status,
    required VoidCallback onStart,
    required VoidCallback onPause,
    required VoidCallback onResume,
    required VoidCallback onCancel,
  }) {
    switch (status) {
      case DownloadStatus.notStarted:
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return Semantics(
          label: 'Download AI model', button: true,
          child: ElevatedButton.icon(
            onPressed: onStart, icon: const Icon(Icons.download),
            label: const Text('Download Model (~3GB)'),
          ),
        );
      case DownloadStatus.downloading:
        return Semantics(
          label: 'Pause download', button: true,
          child: ElevatedButton.icon(
            onPressed: onPause, icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(label: 'Resume download', button: true,
              child: ElevatedButton.icon(onPressed: onResume,
                icon: const Icon(Icons.play_arrow), label: const Text('Resume'))),
            const SizedBox(width: 12),
            Semantics(label: 'Cancel download', button: true,
              child: OutlinedButton.icon(onPressed: onCancel,
                icon: const Icon(Icons.cancel), label: const Text('Cancel'))),
          ],
        );
      case DownloadStatus.completed:
        return Semantics(
          label: 'Open Blind Vision Assistant', button: true,
          child: ElevatedButton.icon(
            onPressed: onStart, icon: const Icon(Icons.visibility),
            label: const Text('Open App'),
          ),
        );
    }
  }
}
