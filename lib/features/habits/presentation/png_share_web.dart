import 'dart:js_interop';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

/// Shares PNG bytes on the web.
///
/// Tries the Web Share API first (`navigator.share` — needs a supporting
/// browser, e.g. mobile Chrome, plus an active user gesture, which an async
/// capture can consume). When that's unavailable or rejected (desktop
/// Chrome, Safari desktop, lost gesture), falls back to a plain browser
/// download of the PNG — so export always works on the Web PWA.
Future<void> sharePngBytes(Uint8List bytes, {required String fileName}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
      ),
    );
    return;
  } catch (_) {
    // Unsupported browser, cancelled share or lost user gesture —
    // fall through to the download.
  }
  _download(bytes, fileName);
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
