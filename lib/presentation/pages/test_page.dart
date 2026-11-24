import 'dart:developer';

import 'package:dsc_lesson/presentation/pages/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  PermissionStatus? permissionStatus;
  bool isLoading = false;
  late final AppLifecycleListener appLifecycleListener;
  @override
  initState() {
    super.initState();
    appLifecycleListener = AppLifecycleListener(
      onResume: () {
        log("رجعنا");
      },
    );
    checkStatus();
  }

  @override
  dispose() {
    appLifecycleListener.dispose();
    super.dispose();
  }

  Future<void> checkStatus() async {
    isLoading = true;
    permissionStatus = await Permission.camera.status;
    setState(() {
      isLoading = false;
      log(permissionStatus!.name);
    });
  }

  Future<void> requestAccessCamera() async {
    isLoading = false;

    permissionStatus = await Permission.camera.request();
    isLoading = false;

    setState(() {});
  }

  Future<void> openAppSetting() async {
    isLoading = true;

    final result = await openAppSettings();
    if (!mounted) return;
    if (result) {
      checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Permission')),
      body: Center(
        child: Column(
          spacing: 20,
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? CircularProgressIndicator()
                : Text(permissionStatus?.name ?? ' checking...'),
            if (permissionStatus == PermissionStatus.permanentlyDenied)
              ElevatedButton(
                onPressed: openAppSetting,
                child: const Text('Open Setting'),
              ),

            if (permissionStatus != PermissionStatus.granted)
              ElevatedButton(
                onPressed: requestAccessCamera,
                child: const Text('Allow camera'),
              )
            else
              CameraView(),
          ],
        ),
      ),
    );
  }
}
