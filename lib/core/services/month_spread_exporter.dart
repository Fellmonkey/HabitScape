import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/result.dart';
import 'png_share_contract.dart';
import 'png_share_stub.dart' if (dart.library.js_interop) 'png_share_web.dart';

/// Captures and shares a PNG "photo" of the month spread.
/// Rendering happens off-screen so the full month — grid + moments, taller
/// than one screen — lands in the image.
class MonthSpreadExporter {
  const MonthSpreadExporter();

  /// Renders the widget at [width] off-screen. A failed capture is an [Err],
  /// never a silent null.
  Future<ui.Image?> _capture(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    return boundary.toImage(pixelRatio: 2.0);
  }

  Future<Result<Uint8List>> capturePng(
    BuildContext context,
    Widget widget, {
    required double width,
  }) async {
    final key = GlobalKey();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        // Far off the left edge: painted but invisible, no flash or clipping.
        left: -100000,
        top: 0,
        width: width,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: RepaintBoundary(
            key: key,
            child: SizedBox(width: width, child: widget),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final image = await _capture(key);
      if (image == null) {
        return Err(StateError('No repaint boundary to capture'));
      }
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        return Err(StateError('PNG conversion produced no bytes'));
      }
      return Ok(data.buffer.asUint8List());
    } catch (error) {
      return Err(error);
    } finally {
      entry.remove();
    }
  }

  /// Shares PNG bytes. Every platform adapter returns the same vocabulary
  /// ([ShareOutcome]) — the caller maps it, never catches platform quirks.
  Future<ShareOutcome> sharePng(Uint8List bytes, {required String fileName}) {
    return sharePngBytes(bytes, fileName: fileName);
  }
}

final monthSpreadExporterProvider = Provider<MonthSpreadExporter>(
  (ref) => const MonthSpreadExporter(),
);
