import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../domain/entities/document_scan_failure.dart';

/// Öffnet die Rückkamera, auf Geräten ohne sie die vorhandene.
Future<web.MediaStream> openEnvironmentCamera() {
  final constraints = web.MediaStreamConstraints(
    video: web.MediaTrackConstraints(
      facingMode: {'ideal': 'environment'}.jsify()!,
      width: {'ideal': 1920}.jsify()!,
      height: {'ideal': 1080}.jsify()!,
    ),
  );
  return web.window.navigator.mediaDevices.getUserMedia(constraints).toDart;
}

void stopCamera(web.MediaStream stream) {
  for (final track in stream.getTracks().toDart) {
    track.stop();
  }
}

/// Der Browser meldet die Ursache nur im Namen des Fehlers, etwa
/// `NotAllowedError`; auf unsicheren Seiten fehlt `mediaDevices` ganz.
DocumentScanFailure cameraFailureFrom(Object error) {
  final text = error.toString();
  final denied =
      text.contains('NotAllowedError') || text.contains('SecurityError');
  return DocumentScanFailure(
    denied
        ? DocumentScanFailureKind.permissionDenied
        : DocumentScanFailureKind.cameraUnavailable,
  );
}
