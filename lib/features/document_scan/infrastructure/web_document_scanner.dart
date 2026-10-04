import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:multiple_result/multiple_result.dart';
import 'package:web/web.dart' as web;

import '../domain/entities/document_scan_failure.dart';
import '../domain/repositories/document_scanner.dart';
import 'web_camera.dart';
import 'web_document_scan_session.dart';
import 'web_scan_bridge.dart';

DocumentScanner createDocumentScanner() => WebDocumentScanner();

class WebDocumentScanner implements DocumentScanner {
  WebDocumentScanner();

  int _sessions = 0;

  @override
  Future<Result<DocumentScanSession, DocumentScanFailure>> open() async {
    final streamOrFailure = await _openCamera();
    return streamOrFailure.when(
      _openWithCamera,
      (failure) async => Error(failure),
    );
  }

  Future<Result<DocumentScanSession, DocumentScanFailure>> _openWithCamera(
    web.MediaStream stream,
  ) async {
    final engineFailure = await _loadEngine();
    if (engineFailure == null) return Success(await _startSession(stream));
    stopCamera(stream);
    return Error(engineFailure);
  }

  Future<Result<web.MediaStream, DocumentScanFailure>> _openCamera() async {
    try {
      return Success(await openEnvironmentCamera());
    } on Object catch (error) {
      return Error(cameraFailureFrom(error));
    }
  }

  Future<DocumentScanFailure?> _loadEngine() async {
    try {
      await initScanEngine().toDart;
      return null;
    } on Object {
      return const DocumentScanFailure(
        DocumentScanFailureKind.engineUnavailable,
      );
    }
  }

  Future<DocumentScanSession> _startSession(web.MediaStream stream) async {
    final video = _previewVideo(stream);
    final previewId = 'novooa-document-scan-${_sessions++}';
    ui_web.platformViewRegistry.registerViewFactory(previewId, (_) => video);
    await video.play().toDart;
    return WebDocumentScanSession(
      previewId: previewId,
      video: video,
      stream: stream,
    );
  }

  web.HTMLVideoElement _previewVideo(web.MediaStream stream) {
    final video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..playsInline = true
      ..srcObject = stream;
    video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'contain';
    return video;
  }
}
