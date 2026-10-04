import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Gegenstück zu `web/document_scanner/document_scanner_bridge.js`.
@JS('novooaDocumentScanner.init')
external JSPromise<JSAny?> initScanEngine();

@JS('novooaDocumentScanner.detect')
external JSString? detectQuadJson(web.HTMLVideoElement video);

@JS('novooaDocumentScanner.capture')
external JSPromise<JSArrayBuffer> captureJpeg(
  web.HTMLVideoElement video,
  JSString? quadJson,
);
