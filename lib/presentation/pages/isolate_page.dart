import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Top-level function: safe to send to an isolate.
Future<double> averageBrightness(XFile? image) async {
  if (image == null) return 0.0;

  final bytes = await image.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final pixelData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (pixelData == null) return 0.0;

  final pixels = pixelData.buffer.asUint32List();
  var total = 0;
  for (final pixel in pixels) {
    // Extract RGBA components (assuming little-endian RGBA8888)
    final r = pixel & 0xFF;
    final g = (pixel >> 8) & 0xFF;
    final b = (pixel >> 16) & 0xFF;
    // Standard luminance formula
    total += (0.299 * r + 0.587 * g + 0.114 * b).round();
  }
  return total / pixels.length;
}

class IsolateDemoPage extends StatefulWidget {
  const IsolateDemoPage({this.image, super.key});
  final XFile? image;
  @override
  State<IsolateDemoPage> createState() => _IsolateDemoPageState();
}

class _IsolateDemoPageState extends State<IsolateDemoPage> {
  String _text = 'no result yet';

  Future<void> _runOnMain() async {
    final sw = Stopwatch()..start();
    final result = await averageBrightness(widget.image);
    setState(
      () => _text =
          'main: ${result.toStringAsFixed(1)} in ${sw.elapsedMilliseconds} ms',
    );
  }

  Future<void> _runInIsolate() async {
    final sw = Stopwatch()..start();
    final result = await Isolate.run(() => averageBrightness(widget.image));
    setState(
      () => _text =
          'isolate: ${result.toStringAsFixed(1)} in ${sw.elapsedMilliseconds} ms',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isolate demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            const CircularProgressIndicator(),
            Text(_text),
            ElevatedButton(
              onPressed: _runOnMain,
              child: const Text('Run on main'),
            ),
            ElevatedButton(
              onPressed: _runInIsolate,
              child: const Text('Run in isolate'),
            ),
          ],
        ),
      ),
    );
  }
}