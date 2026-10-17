import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/document_scan/domain/entities/document_scan_failure.dart';
import 'package:syscat2/features/document_scan/domain/entities/scanned_document.dart';
import 'package:syscat2/features/document_scan/domain/services/scan_quad_stabilizer.dart';
import 'package:syscat2/features/document_scan/domain/usecases/open_document_scan_session.dart';
import 'package:syscat2/features/document_scan/presentation/cubits/document_scan_cubit.dart';
import 'package:syscat2/features/document_scan/presentation/pages/document_scan_page.dart';
import 'package:syscat2/features/document_scan/presentation/widgets/scan_quad_overlay.dart';

import 'fake_document_scanner.dart';

// Ein gültiges 1x1-PNG, damit Image.memory in der Vorschau etwas dekodieren kann.
final _pixel = ScannedDocument(
  bytes: Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0xF8,
    0xFF,
    0xFF,
    0x3F,
    0x00,
    0x05,
    0xFE,
    0x02,
    0xFE,
    0xA7,
    0x35,
    0x81,
    0x84,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]),
);

const _tick = Duration(milliseconds: 5);

DocumentScanCubit _cubitFor(FakeDocumentScanner scanner) {
  return DocumentScanCubit(
    OpenDocumentScanSession(scanner),
    ScanQuadStabilizer(),
    detectionInterval: _tick,
  );
}

Widget _view(DocumentScanCubit cubit) {
  return MaterialApp(
    home: BlocProvider.value(value: cubit, child: const DocumentScanView()),
  );
}

/// Startet den Scanner und lässt die Oberfläche das erste Kamerabild zeigen.
Future<DocumentScanCubit> _scanning(
  WidgetTester tester,
  FakeDocumentScanSession session,
) async {
  final cubit = _cubitFor(FakeDocumentScanner(Success(session)));
  await tester.pumpWidget(_view(cubit));
  await cubit.start();
  await tester.pump();
  return cubit;
}

void main() {
  testWidgets('beim Öffnen steht ein Ladehinweis da', (tester) async {
    final cubit = _cubitFor(
      FakeDocumentScanner(Success(FakeDocumentScanSession())),
    );
    await tester.pumpWidget(_view(cubit));

    expect(find.text('Kamera wird gestartet …'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await cubit.close();
  });

  testWidgets(
    'mit Kamerabild gibt es Hinweis und große Aufnahme-Schaltfläche',
    (tester) async {
      final cubit = await _scanning(tester, FakeDocumentScanSession());

      expect(find.text('Lege das Dokument flach in das Bild.'), findsOneWidget);
      final button = find.widgetWithText(FilledButton, 'Aufnehmen');
      expect(button, findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await cubit.close();
    },
  );

  testWidgets('eine erkannte Kontur wird gezeichnet und angesagt', (
    tester,
  ) async {
    final session = FakeDocumentScanSession(
      detections: [documentQuad, documentQuad],
    );
    final cubit = await _scanning(tester, session);

    await tester.pump(_tick * 3);
    await tester.pump(_tick * 3);

    expect(
      find.text('Dokument erkannt. Zum Aufnehmen tippen.'),
      findsOneWidget,
    );
    final overlay = tester.widget<ScanQuadOverlay>(
      find.byType(ScanQuadOverlay),
    );
    expect(overlay.quad, isNotNull);
    await cubit.close();
  });

  testWidgets('Wiederholen in der Vorschau führt zurück zum Kamerabild', (
    tester,
  ) async {
    final session = FakeDocumentScanSession()..captureResult = Success(_pixel);
    final cubit = await _scanning(tester, session);
    await tester.tap(find.text('Aufnehmen'));
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsLabel('Gescanntes Dokument'), findsOneWidget);

    await tester.tap(find.text('Wiederholen'));
    await tester.pump();

    expect(find.text('Aufnehmen'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Übernehmen schließt die Seite und gibt das Dokument zurück', (
    tester,
  ) async {
    final session = FakeDocumentScanSession()..captureResult = Success(_pixel);
    final cubit = _cubitFor(FakeDocumentScanner(Success(session)));
    ScannedDocument? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push(
                MaterialPageRoute<ScannedDocument>(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const DocumentScanView(),
                  ),
                ),
              );
            },
            child: const Text('Start'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await cubit.start();
    await tester.pump();
    await tester.tap(find.text('Aufnehmen'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Übernehmen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, same(_pixel));
    expect(find.byType(DocumentScanView), findsNothing);
    await cubit.close();
  });

  testWidgets('ein Kameraproblem zeigt die Meldung mit „Erneut versuchen“', (
    tester,
  ) async {
    final scanner = FakeDocumentScanner(
      const Error(
        DocumentScanFailure(DocumentScanFailureKind.permissionDenied),
      ),
    );
    final cubit = _cubitFor(scanner);
    await tester.pumpWidget(_view(cubit));
    await cubit.start();
    await tester.pump();

    expect(
      find.textContaining('Kamerazugriff wurde verweigert'),
      findsOneWidget,
    );
    expect(find.text('Schließen'), findsOneWidget);

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();

    expect(scanner.opens, 2);
    await cubit.close();
  });

  testWidgets('ohne Scanner gibt es kein „Erneut versuchen“, nur „Schließen“', (
    tester,
  ) async {
    final cubit = _cubitFor(
      FakeDocumentScanner(
        const Error(DocumentScanFailure(DocumentScanFailureKind.unsupported)),
      ),
    );
    await tester.pumpWidget(_view(cubit));
    await cubit.start();
    await tester.pump();

    expect(find.text('Erneut versuchen'), findsNothing);
    expect(find.text('Schließen'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('bei kleinem Fenster und großer Schrift läuft nichts über', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = _cubitFor(
      FakeDocumentScanner(
        const Error(
          DocumentScanFailure(DocumentScanFailureKind.cameraUnavailable),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: BlocProvider.value(value: cubit, child: const DocumentScanView()),
      ),
    );
    await cubit.start();
    await tester.pump();

    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  test('die Seite lässt sich als Route öffnen', () {
    expect(DocumentScanPage.open, isA<Function>());
  });
}
