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
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final result = await Permission.camera.status;
    setState(() => status = result);
  }

  Future<void> _requestPermission() async {
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
          children: [
            Text(status?.name ?? 'checking...'),
            if (status != PermissionStatus.granted)
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('Allow camera'),
              ),
          ],
        ),
      ),
    );
  }
}
