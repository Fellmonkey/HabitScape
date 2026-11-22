export 'connection_stub.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    if (dart.library.ffi) 'connection_native.dart';
