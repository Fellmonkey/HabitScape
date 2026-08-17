import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Shares PNG bytes through the platform share sheet (non-web build).
/// Throws on failure — the caller surfaces a snackbar.
Future<void> sharePngBytes(Uint8List bytes, {required String fileName}) {
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
    ),
  );
}
