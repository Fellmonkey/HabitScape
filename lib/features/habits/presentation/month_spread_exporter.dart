import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'png_share_stub.dart' if (dart.library.js_interop) 'png_share_web.dart';

/// Captures and shares a «photo» of the «Разворот месяца» (PNG), like
/// photographing a paper planner spread.
///
/// Rendering happens off-screen (an invisible overlay entry far off the
/// screen edge), so the full month — grid + moments, taller than one screen —
/// lands in the image, not just the visible viewport.
class MonthSpreadExporter {
  const MonthSpreadExporter();

  /// Renders [widget] at [width] off-screen and returns PNG bytes,
  /// or `null` when the capture failed (test doubles override this method).
  Future<ui.Image?> _capture(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    return boundary.toImage(pixelRatio: 2.0);
  }

  Future<Uint8List?> capturePng(
    BuildContext context,
    Widget widget, {
    required double width,
  }) async {
    final key = GlobalKey();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        // Far off the left edge: painted but invisible, so there is no flash
        // and no ancestor clipping affects the RepaintBoundary's own layer.
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
      if (image == null) return null;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      entry.remove();
    }
  }

  /// Shares the PNG bytes. On the web this may fall back to a download;
  /// on native platforms it opens the system share sheet. Throws on failure.
  Future<void> sharePng(Uint8List bytes, {required String fileName}) {
    return sharePngBytes(bytes, fileName: fileName);
  }
}

final monthSpreadExporterProvider = Provider<MonthSpreadExporter>(
  (ref) => const MonthSpreadExporter(),
);
