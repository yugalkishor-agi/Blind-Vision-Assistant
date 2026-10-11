// main.dart
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:blind_vision_assistant/download_page/model_download_page.dart';
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
      title: 'Blind Vision Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7C3AED),       // electric violet
          secondary: const Color(0xFF06B6D4),     // cyan neon
          tertiary: const Color(0xFFEC4899),      // hot pink
          surface: const Color(0xFF0F0F1A),       // deep void
          surfaceContainerHighest: const Color(0xFF1A1A2E),
          onPrimary: Colors.white,
          onSurface: const Color(0xFFE2E8F0),
          outline: const Color(0xFF2D2D3F),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFFCBD5E1)),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
          bodySmall: TextStyle(color: Color(0xFF64748B)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A14),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFF94A3B8)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF12121E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E1E30), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF12121E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2D2D3F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2D2D3F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF475569)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      // Set the initial page to the model download screen
      // Users must download the ML model before they can use the chat feature
      home: const ModelDownloadPage(),
    );
  }
}
