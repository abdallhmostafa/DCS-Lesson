import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  cam.CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  void _startCamera() async {
    final cameras = await cam.availableCameras();
    final controller = cam.CameraController(
      cameras.first,
      cam.ResolutionPreset.high,
    );
    await controller.initialize();

    setState(() {
      _cameraController = controller;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _cameraController == null
        ? CircularProgressIndicator()
        : cam.CameraPreview(_cameraController!);
  }
}
