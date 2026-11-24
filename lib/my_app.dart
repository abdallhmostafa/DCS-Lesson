import 'package:dsc_lesson/presentation/pages/camera_permission_page.dart';
import 'package:dsc_lesson/presentation/pages/isolate_page.dart';
import 'package:flutter/material.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const IsolateDemoPage());
  }
}
