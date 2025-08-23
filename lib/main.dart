import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/services/foreground_service_manager.dart';
import 'package:youtube_downloader/core/PermissionHandler.dart';
import 'package:youtube_downloader/services/notification_service.dart';
import 'package:youtube_downloader/view/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PermissionHandler.ensurePermissions();
  ForegroundServiceManager.init();
  await ForegroundServiceManager.start();
  await NotificationService.init();
  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      theme: ThemeData(primaryColor: Colors.red, useMaterial3: true),
      debugShowCheckedModeBanner: false,
    );
  }
}
