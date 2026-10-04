import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:web/web.dart' as web;

import '../domain/entities/document_scan_failure.dart';
import '../domain/entities/scan_quad.dart';
import '../domain/entities/scanned_document.dart';
import '../domain/repositories/document_scanner.dart';
import 'web_camera.dart';
import 'web_scan_bridge.dart';

class WebDocumentScanSession implements DocumentScanSession {
  WebDocumentScanSession({
    required this.previewId,
    required this._video,
    required this._stream,
  });

  @override
  final String previewId;

  final web.HTMLVideoElement _video;
  final web.MediaStream _stream;

  @override
  double get aspectRatio {
    final width = _video.videoWidth;
    final height = _video.videoHeight;
    return width > 0 && height > 0 ? width / height : 4 / 3;
  }

  @override
  Future<ScanQuad?> detect() async {
    try {
      return _quadFrom(detectQuadJson(_video)?.toDart);
    } on Object {
      return null;
    }
  }

  @override
  Future<Result<ScannedDocument, DocumentScanFailure>> capture(
    ScanQuad? quad,
  ) async {
    try {
      final buffer = await captureJpeg(_video, _jsonFrom(quad)?.toJS).toDart;
      final bytes = Uint8List.view(buffer.toDart);
      return Success(ScannedDocument(bytes: bytes));
    } on Object {
      return const Error(
        DocumentScanFailure(DocumentScanFailureKind.captureFailed),
      );
    }
  }

  @override
  Future<void> close() async {
    stopCamera(_stream);
    _video.pause();
    _video.srcObject = null;
  }

  ScanQuad? _quadFrom(String? json) {
    if (json == null) return null;
    final values = (jsonDecode(json) as List<dynamic>).cast<num>();
    return ScanQuad.fromValues([for (final value in values) value.toDouble()]);
  }

  String? _jsonFrom(ScanQuad? quad) {
    if (quad == null) return null;
    return jsonEncode([
      for (final corner in quad.corners) ...[corner.x, corner.y],
    ]);
  }
}
