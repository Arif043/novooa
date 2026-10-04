import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/scan_quad.dart';
import '../../domain/repositories/document_scanner.dart';
import '../../domain/usecases/open_document_scan_session.dart';
import 'document_scan_state.dart';

class DocumentScanCubit extends Cubit<DocumentScanState> {
  DocumentScanCubit(
    this._openSession, {
    this.detectionInterval = const Duration(milliseconds: 200),
  }) : super(const DocumentScanOpening());

  /// Nach so vielen Bildern ohne Treffer verschwindet die Kontur; kurze
  /// Aussetzer lassen sie stehen, damit sie nicht flackert.
  static const int _missedFramesBeforeHiding = 3;

  final OpenDocumentScanSession _openSession;
  final Duration detectionInterval;

  DocumentScanSession? _session;
  Timer? _detectionTimer;
  int _missedFrames = 0;

  Future<void> start() async {
    emit(const DocumentScanOpening());
    final sessionOrFailure = await _openSession();
    await sessionOrFailure.when(_begin, (failure) async {
      if (!isClosed) emit(DocumentScanFailed(failure));
    });
  }

  Future<void> capture() async {
    final session = _session;
    final current = state;
    if (session == null || current is! DocumentScanScanning) return;
    _detectionTimer?.cancel();
    emit(
      DocumentScanCapturing(
        previewId: current.previewId,
        aspectRatio: current.aspectRatio,
        quad: current.quad,
      ),
    );
    final documentOrFailure = await session.capture(current.quad);
    if (isClosed) return;
    documentOrFailure.when(
      (document) => emit(DocumentScanReview(document)),
      (failure) => emit(DocumentScanFailed(failure)),
    );
  }

  /// Zurück zum Kamerabild, etwa nach einer Vorschau oder einer missglückten Aufnahme.
  Future<void> retry() {
    if (_session == null) return start();
    _resumeScanning(_session!);
    return Future.value();
  }

  Future<void> _begin(DocumentScanSession session) async {
    if (isClosed) return session.close();
    _session = session;
    _resumeScanning(session);
  }

  void _resumeScanning(DocumentScanSession session) {
    _missedFrames = 0;
    emit(
      DocumentScanScanning(
        previewId: session.previewId,
        aspectRatio: session.aspectRatio,
      ),
    );
    _scheduleDetection();
  }

  void _scheduleDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(detectionInterval, _detect);
  }

  Future<void> _detect() async {
    final session = _session;
    if (session == null || state is! DocumentScanScanning) return;
    final quad = await session.detect();
    if (isClosed || state is! DocumentScanScanning) return;
    _showQuad(session, quad);
    _scheduleDetection();
  }

  void _showQuad(DocumentScanSession session, ScanQuad? detected) {
    final current = state as DocumentScanScanning;
    _missedFrames = detected == null ? _missedFrames + 1 : 0;
    final keep = detected == null && _missedFrames < _missedFramesBeforeHiding;
    emit(
      DocumentScanScanning(
        previewId: session.previewId,
        aspectRatio: session.aspectRatio,
        quad: keep ? current.quad : detected,
      ),
    );
  }

  @override
  Future<void> close() async {
    _detectionTimer?.cancel();
    final session = _session;
    _session = null;
    // Erst als geschlossen markieren: Öffnet sich die Kamera gerade noch, gibt
    // `_begin` sie dann sofort wieder frei.
    await super.close();
    await session?.close();
  }
}
