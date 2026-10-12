// main.dart
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:blind_vision_assistant/download_page/model_download_page.dart';
import 'package:blind_vision_assistant/chat_page/gemma_vision_chat.dart';
import 'package:blind_vision_assistant/chat_page/services/remote_settings_manager.dart';
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
        useMaterial3: false,
        brightness: Brightness.light,
        // ── Brutalist editorial palette ───────────────────────────────────
        scaffoldBackgroundColor: const Color(0xFFF5F0E8), // warm cream
        colorScheme: const ColorScheme.light(
          primary:   Color(0xFF1A1A1A), // near-black
          secondary: Color(0xFFE8441A), // orange-red accent
          tertiary:  Color(0xFFE8441A),
          surface:   Color(0xFFF5F0E8),
          onPrimary: Color(0xFFF5F0E8),
          onSecondary: Color(0xFFF5F0E8),
          onSurface: Color(0xFF1A1A1A),
          outline:   Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F0E8),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFF5F0E8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Color(0xFF1A1A1A), width: 2),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFEDE8DF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFE8441A), width: 2.5),
          ),
          hintStyle: TextStyle(color: Color(0xFF888070), fontFamily: 'monospace'),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerColor: const Color(0xFF1A1A1A),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900),
          displayMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900),
          headlineLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900),
          headlineMedium:TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800),
          headlineSmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800),
          titleLarge:    TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700),
          bodyLarge:     TextStyle(color: Color(0xFF1A1A1A)),
          bodyMedium:    TextStyle(color: Color(0xFF3A3530)),
          bodySmall:     TextStyle(color: Color(0xFF666050), fontFamily: 'monospace'),
        ),
      ),
      home: const _AppRouter(),
    );
  }
}

/// Checks remote settings on startup and routes to the correct page.
/// - Remote mode ON + URL set → ChatPage (skip download entirely)
/// - Otherwise → ModelDownloadPage (normal flow)
class _AppRouter extends StatefulWidget {
  const _AppRouter();
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final isRemote = await RemoteSettingsManager.isRemoteEnabled();
    if (!mounted) return;
    if (isRemote) {
      // Remote mode — skip download page, go straight to chat
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ModelDownloadPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Brief loading screen while we check SharedPreferences
    return const Scaffold(
      backgroundColor: Color(0xFFF5F0E8),
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFE8441A),
          ),
        ),
      ),
    );
  }
}
