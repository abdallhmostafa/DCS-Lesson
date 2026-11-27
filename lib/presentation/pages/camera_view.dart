import 'package:camera/camera.dart' as cam;
import 'package:dsc_lesson/presentation/pages/isolate_page.dart';
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
    startCamera();
  }

  void startCamera() async {
    final cameras = await cam.availableCameras();
    cameraController = cam.CameraController(
      cameras.first,
      cam.ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController?.initialize();

    setState(() {});
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: cameraController == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Expanded(flex: 3, child: cam.CameraPreview(cameraController!)),
                Flexible(
                  child: FilledButton(
                    onPressed: () async {
                      final image = await cameraController?.takePicture();
                      if (image == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IsolateDemoPage(image: image),
                        ),
                      );
                    },
                    child: Text("Take Picture"),
                  ),
                ),
              ],
            ),
    );
  }
}
