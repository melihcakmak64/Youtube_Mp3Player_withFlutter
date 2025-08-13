import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/services/NotificationService.dart';
import 'package:youtube_downloader/core/PermissionHandler.dart';
import 'view/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PermissionHandler.checkPermission();
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
