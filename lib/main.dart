import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'view/HomePage.dart';

void main() {
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
