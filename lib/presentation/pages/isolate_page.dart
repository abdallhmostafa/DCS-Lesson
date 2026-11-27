import 'dart:isolate';
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// Heavy CPU work: loops over every pixel to get the average brightness.
double computeAverageBrightness(Uint8List rgba) {
  var total = 0.0;
  for (var i = 0; i < rgba.length; i += 4) {
    total += 0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2];
  }
  return total / (rgba.length ~/ 4);
}

Future<double> brightnessInIsolate(Uint8List rgba) =>
    Isolate.run(() => computeAverageBrightness(rgba));

class IsolateDemoPage extends StatefulWidget {
  const IsolateDemoPage({required this.image, super.key});

  final XFile image;

  @override
  State<IsolateDemoPage> createState() => _IsolateDemoPageState();
}

class _IsolateDemoPageState extends State<IsolateDemoPage> {
  String _text = 'no result yet';

  Future<Uint8List> _loadPixels() async {
    final bytes = await widget.image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 4000);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    return data!.buffer.asUint8List();
  }

  Future<void> _runOnMain() async {
    final rgba = await _loadPixels();
    final sw = Stopwatch()..start();
    final result = computeAverageBrightness(rgba);
    setState(
      () => _text =
          'main: ${result.toStringAsFixed(1)} in ${sw.elapsedMilliseconds} ms',
    );
  }

  Future<void> _runInIsolate() async {
    final rgba = await _loadPixels();
    final sw = Stopwatch()..start();
    final result = await brightnessInIsolate(rgba);
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
