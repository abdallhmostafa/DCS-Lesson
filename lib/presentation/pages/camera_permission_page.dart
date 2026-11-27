import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionPage extends StatefulWidget {
  const CameraPermissionPage({super.key});

  @override
  State<CameraPermissionPage> createState() => _CameraPermissionPageState();
}

class _CameraPermissionPageState extends State<CameraPermissionPage> {
  PermissionStatus? status;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  Future<void> checkStatus() async {
    final result = await Permission.camera.status;
    setState(() => status = result);
  }

  Future<void> requestPermission() async {
    final result = await Permission.camera.request();
    setState(() => status = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Permission')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            Text(
              status?.name ?? 'Checking...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (status != PermissionStatus.granted)
              ElevatedButton(
                onPressed: requestPermission,
                child: const Text('Allow camera'),
              ),
          ],
        ),
      ),
    );
  }
}
