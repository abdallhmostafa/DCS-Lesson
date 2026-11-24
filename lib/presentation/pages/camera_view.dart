import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  cam.CameraController? cameraController;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  void _startCamera() async {
    final cameras = await cam.availableCameras();
    final cameraController = cam.CameraController(
      cameras.first,
      cam.ResolutionPreset.high,
    );

    await cameraController.initialize(); // risky code

    setState(() {});
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return cameraController == null
        ? CircularProgressIndicator()
        : cam.CameraPreview(cameraController!);
  }
}
