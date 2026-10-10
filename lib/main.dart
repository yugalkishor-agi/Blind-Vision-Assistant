// main.dart
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:gemma_chat/download_page/model_download_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Top-level callback function for handling download progress updates.
/// This function is called by the background isolate when download status changes.
///
/// IMPORTANT: This must be a top-level function (not inside a class) and marked
/// with @pragma('vm:entry-point') so the Dart VM can find it when running
/// in the background isolate. The background downloader runs in a separate
/// isolate from the main UI thread for performance reasons.
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  // Look up the SendPort that was registered with the isolate name server
  // This allows communication between the background isolate and main isolate
  final SendPort? send = IsolateNameServer.lookupPortByName(
    'downloader_send_port',
  );

  // Send download progress data to the main isolate
  // Data format: [taskId, status, progress_percentage]
  send?.send([id, status, progress]);
}

/// App entry point - initializes all required services before starting the UI.
Future<void> main() async {
  // Ensure Flutter binding is initialized before calling platform-specific code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the flutter_downloader plugin for background downloads
  // This must be done before any download operations can be performed
  await FlutterDownloader.initialize(
    debug: kDebugMode, // Enable detailed logs only in debug mode
    ignoreSsl: false, // Set to true only if you need to download from HTTP URLs
  );

  // Register our callback function so the background downloader can call it
  // The downloader will use this callback to report progress updates
  FlutterDownloader.registerCallback(downloadCallback);

  // This prevents the device from sleeping and potentially interrupting downloads
  await WakelockPlus.enable();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma Vision',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),

      // Set the initial page to the model download screen
      // Users must download the ML model before they can use the chat feature
      home: const ModelDownloadPage(),
    );
  }
}
