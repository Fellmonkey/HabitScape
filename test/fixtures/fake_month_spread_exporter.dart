import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:rythm/features/habits/presentation/month_spread_exporter.dart';
import 'package:rythm/features/habits/presentation/png_share_contract.dart';

/// [MonthSpreadExporter] double: skips the real offscreen rasterization and
/// the platform share sheet, recording what the screen would have shared.
class FakeMonthSpreadExporter implements MonthSpreadExporter {
  /// Number of successful `sharePng` calls.
  int shareCalls = 0;

  String? lastFileName;
  Uint8List? lastBytes;

  /// Number of `capturePng` calls.
  int captureCalls = 0;

  /// If set, `capturePng` returns this instead of the default payload.
  Uint8List? captureResult;

  /// What `sharePng` reports; tests flip it to exercise the failure paths.
  ShareOutcome shareOutcome = ShareOutcome.shared;

  @override
  Future<Uint8List?> capturePng(
    BuildContext context,
    Widget widget, {
    required double width,
  }) async {
    captureCalls++;
    return captureResult ?? Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<ShareOutcome> sharePng(
    Uint8List bytes, {
    required String fileName,
  }) async {
    shareCalls++;
    lastBytes = bytes;
    lastFileName = fileName;
    return shareOutcome;
  }
}
