import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/services/PermissionHandler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'view/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PermissionHandler.chekPermission();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: HomePage(),
      theme: ThemeData(primaryColor: Colors.red, useMaterial3: true),
      debugShowCheckedModeBanner: false,
    );
  }
}
