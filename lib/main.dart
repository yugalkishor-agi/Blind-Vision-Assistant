import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:gemma_chat/download_page/model_download_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart'

@pragma('vm:entry-point')
void downloadcallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
        'downloader_send_port',
    );

    send?.send([id, status, progress]);
}


Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();


  await FlutterDownloader.initialize(
    debug: kDebugMode, 
    ignoreSsl: false, 
  );


  FlutterDownloader.registerCallback(downloadCallback);


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


      home: const ModelDownloadPage(),
    );
  }
}
