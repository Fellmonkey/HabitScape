import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/theme/app_theme.dart';

/// Exercises the real rasterization pipeline (`RenderRepaintBoundary.toImage`
/// + PNG encoding) with genuine widgets — the half of the export path the
/// fake-exporter screen tests skip. The off-screen overlay plumbing is
/// covered by `month_spread_export_test.dart` via the fake adapter; together
/// they pin the whole PNG export contract.
void main() {
  testWidgets('a real widget tree rasterizes into PNG bytes', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: 320,
              height: 200,
              color: const Color(0xFF112233),
              alignment: Alignment.center,
              child: const Text(
                'Момент дня',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Uint8List? bytes;
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject();
      expect(boundary, isA<RenderRepaintBoundary>());
      final image = await (boundary as RenderRepaintBoundary).toImage(
        pixelRatio: 2.0,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = data?.buffer.asUint8List();
    });

    expect(bytes, isNotNull);
    final png = bytes!;
    expect(png.length, greaterThan(100));
    // PNG signature: 89 50 4E 47 0D 0A 1A 0A.
    expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  });
}
