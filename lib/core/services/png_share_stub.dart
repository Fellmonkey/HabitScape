import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'png_share_contract.dart';

/// Shares PNG bytes through the platform share sheet (non-web build).
///
/// Reports every failure as [ShareOutcome.failed] — the caller maps it to a
/// message instead of guessing.
Future<ShareOutcome> sharePngBytes(
  Uint8List bytes, {
  required String fileName,
}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
      ),
    );
    return ShareOutcome.shared;
  } catch (_) {
    return ShareOutcome.failed;
  }
}
