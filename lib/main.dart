import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'view/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermission();
  runApp(const MainApp());
}

Future<void> _requestPermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
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
