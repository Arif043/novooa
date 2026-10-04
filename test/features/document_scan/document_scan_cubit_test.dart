import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/document_scan/domain/entities/document_scan_failure.dart';
import 'package:syscat2/features/document_scan/domain/usecases/open_document_scan_session.dart';
import 'package:syscat2/features/document_scan/presentation/cubits/document_scan_cubit.dart';
import 'package:syscat2/features/document_scan/presentation/cubits/document_scan_state.dart';

import 'fake_document_scanner.dart';

const _interval = Duration(milliseconds: 5);

DocumentScanCubit _cubit(FakeDocumentScanner scanner) => DocumentScanCubit(
  OpenDocumentScanSession(scanner),
  detectionInterval: _interval,
);

Future<void> _until(
  DocumentScanCubit cubit,
  bool Function(DocumentScanState) test,
) {
  return cubit.stream.firstWhere(test).timeout(const Duration(seconds: 2));
}

void main() {
  test('öffnet die Kamera und zeigt danach das Kamerabild', () async {
    final session = FakeDocumentScanSession();
    final cubit = _cubit(FakeDocumentScanner(Success(session)));
    addTearDown(cubit.close);

    expect(cubit.state, isA<DocumentScanOpening>());
    await cubit.start();

    final state = cubit.state as DocumentScanScanning;
    expect(state.previewId, 'preview-1');
    expect(state.aspectRatio, 4 / 3);
    expect(state.quad, isNull);
  });

  test(
    'zeigt die erkannte Kontur und lässt sie bei kurzen Aussetzern stehen',
    () async {
      final session = FakeDocumentScanSession(
        detections: [documentQuad, null, null],
      );
      final cubit = _cubit(FakeDocumentScanner(Success(session)));
      addTearDown(cubit.close);
      await cubit.start();

      await _until(cubit, (s) => s is DocumentScanScanning && s.quad != null);
      await Future<void>.delayed(_interval * 6);

      expect(
        (cubit.state as DocumentScanScanning).quad,
        isNull,
        reason: 'nach drei Bildern ohne Treffer verschwindet die Kontur',
      );
    },
  );

  test(
    'ein Kameraproblem wird zum Failure-Zustand und lässt sich wiederholen',
    () async {
      final session = FakeDocumentScanSession();
      final scanner = FakeDocumentScanner(
        const Error(
          DocumentScanFailure(DocumentScanFailureKind.permissionDenied),
        ),
      );
      final cubit = _cubit(scanner);
      addTearDown(cubit.close);

      await cubit.start();
      final failed = cubit.state as DocumentScanFailed;
      expect(failed.failure.kind, DocumentScanFailureKind.permissionDenied);
      expect(failed.failure.isRetryable, isTrue);

      await cubit.retry();
      expect(
        scanner.opens,
        2,
        reason: 'ohne Sitzung wird die Kamera neu geöffnet',
      );
      expect(session.closed, isFalse);
    },
  );

  test(
    'die Aufnahme nutzt die zuletzt erkannte Kontur und zeigt die Vorschau',
    () async {
      final session = FakeDocumentScanSession(detections: [documentQuad]);
      final cubit = _cubit(FakeDocumentScanner(Success(session)));
      addTearDown(cubit.close);
      await cubit.start();
      await _until(cubit, (s) => s is DocumentScanScanning && s.quad != null);

      await cubit.capture();

      expect(session.capturedWith, same(documentQuad));
      final review = cubit.state as DocumentScanReview;
      expect(review.document.bytes, Uint8List.fromList([1, 2, 3]));
    },
  );

  test('Wiederholen aus der Vorschau geht zurück zum Kamerabild', () async {
    final session = FakeDocumentScanSession();
    final cubit = _cubit(FakeDocumentScanner(Success(session)));
    addTearDown(cubit.close);
    await cubit.start();
    await cubit.capture();
    expect(cubit.state, isA<DocumentScanReview>());

    await cubit.retry();

    expect(cubit.state, isA<DocumentScanScanning>());
    expect(session.captureCalls, 1);
  });

  test(
    'eine missglückte Aufnahme meldet den Fehler, die Kamera bleibt offen',
    () async {
      final session = FakeDocumentScanSession()
        ..captureResult = const Error(
          DocumentScanFailure(DocumentScanFailureKind.captureFailed),
        );
      final cubit = _cubit(FakeDocumentScanner(Success(session)));
      addTearDown(cubit.close);
      await cubit.start();

      await cubit.capture();

      expect(
        (cubit.state as DocumentScanFailed).failure.kind,
        DocumentScanFailureKind.captureFailed,
      );
      expect(session.closed, isFalse);
      await cubit.retry();
      expect(cubit.state, isA<DocumentScanScanning>());
    },
  );

  test('Schließen gibt die Kamera frei', () async {
    final session = FakeDocumentScanSession();
    final cubit = _cubit(FakeDocumentScanner(Success(session)));
    await cubit.start();

    await cubit.close();

    expect(session.closed, isTrue);
  });

  test(
    'wird der Scanner geschlossen, bevor die Kamera da ist, wird sie sofort freigegeben',
    () async {
      final session = FakeDocumentScanSession();
      final cubit = _cubit(FakeDocumentScanner(Success(session)));

      final starting = cubit.start();
      await cubit.close();
      await starting;

      expect(session.closed, isTrue);
    },
  );

  test('unsupported ist nicht wiederholbar', () {
    const failure = DocumentScanFailure(DocumentScanFailureKind.unsupported);
    expect(failure.isRetryable, isFalse);
  });
}
