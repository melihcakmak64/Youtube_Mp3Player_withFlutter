import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/core/PermissionHandler.dart';
import 'package:youtube_downloader/view/ExamplePage.dart';

void main() async {
  FlutterForegroundTask.initCommunicationPort();
  WidgetsFlutterBinding.ensureInitialized();

  await PermissionHandler.ensurePermissions();

  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExamplePage(),
      theme: ThemeData(primaryColor: Colors.red, useMaterial3: true),
      debugShowCheckedModeBanner: false,
    );
  }
}
