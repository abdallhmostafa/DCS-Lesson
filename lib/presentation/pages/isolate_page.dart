import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Top-level function: safe to send to an isolate.
double averageBrightness(int pixelCount) {
  final pixels = Uint8List(pixelCount);
  for (var i = 0; i < pixelCount; i++) {
    pixels[i] = (i * 31) & 255;
  }
  var total = 0;
  for (var pass = 0; pass < 10; pass++) {
    total = 0;
    for (var i = 0; i < pixelCount; i++) {
      total += pixels[i];
    }
  }
  return total / pixelCount;
}

class IsolateDemoPage extends StatefulWidget {
  const IsolateDemoPage({super.key});

  @override
  State<IsolateDemoPage> createState() => _IsolateDemoPageState();
}

class _IsolateDemoPageState extends State<IsolateDemoPage> {
  // final bytes = await file.readAsBytes();
  // final brightness = calculateBrightness(bytes);
  String _text = 'no result yet';
  static const _pixelCount = 12000000;

  void _runOnMain() {
    final sw = Stopwatch()..start();
    final result = averageBrightness(_pixelCount);
    setState(
      () => _text =
          'main: ${result.toStringAsFixed(1)} in ${sw.elapsedMilliseconds} ms',
    );
  }

  Future<void> _runInIsolate() async {
    final sw = Stopwatch()..start();
    final result = await Isolate.run(() => averageBrightness(_pixelCount));
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
