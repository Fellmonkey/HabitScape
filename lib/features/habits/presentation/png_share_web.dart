import 'dart:js_interop';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

import 'png_share_contract.dart';

/// Shares PNG bytes on the web: tries the Web Share API, then falls back
/// to a plain browser download — so export always works on the PWA. The
/// fallback is reported as [ShareOutcome.cancelled] (the file was still
/// delivered), never as an error.
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
    // Unsupported browser, cancelled share or lost gesture — fall through.
  }
  _download(bytes, fileName);
  return ShareOutcome.cancelled;
}

void _download(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  web.URL.revokeObjectURL(url);
}
