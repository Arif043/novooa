import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/knowledge_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/file_attachment_section.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/knowledge_attachment_section.dart';

const _bericht = NodeAttachment(
  id: 'f1:v1',
  storagePath: 'p1',
  generation: 'v1',
  displayName: 'Bericht.pdf',
  contentType: 'application/pdf',
  sizeBytes: 2048,
);
const _notiz = NodeAttachment(
  id: 'f2:v1',
  storagePath: 'p2',
  generation: 'v1',
  displayName: 'Notiz.txt',
  contentType: 'text/plain',
  sizeBytes: 12,
);
const _wiki = KnowledgeAttachment(
  knowledgeBaseId: 'kb',
  noteId: 'n1',
  title: 'Projektplan',
  path: 'projekte/plan.md',
);
const _glossar = KnowledgeAttachment(
  knowledgeBaseId: 'kb',
  noteId: 'n2',
  title: 'Glossar',
  path: 'glossar.md',
);

Widget _files({
  required List<NodeAttachment> attached,
  required List<NodeAttachment> available,
  required ValueChanged<NodeAttachment> onAttach,
}) {
  return MaterialApp(
    home: Scaffold(
      body: FileAttachmentSection(
        attachments: attached,
        availableFiles: available,
        onAttach: onAttach,
        onDetach: (_) {},
      ),
    ),
  );
}

Widget _notes({
  List<KnowledgeAttachment> attached = const [],
  required List<KnowledgeAttachment> available,
  required ValueChanged<KnowledgeAttachment> onAttach,
}) {
  return MaterialApp(
    home: Scaffold(
      body: KnowledgeAttachmentSection(
        attachments: attached,
        availableNotes: available,
        onAttach: onAttach,
        onDetach: (_) {},
      ),
    ),
  );
}

void main() {
  group('Dateien anhängen', () {
    testWidgets(
      'mobil: Bottom Sheet; bereits angehängte Dateien sind nicht wählbar',
      (tester) async {
        NodeAttachment? attached;
        await tester.pumpWidget(
          _files(
            attached: const [_bericht],
            available: const [_bericht, _notiz],
            onAttach: (file) => attached = file,
          ),
        );

        await tester.tap(find.byTooltip('Datei anhängen'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Abbrechen'), findsNothing);
        await tester.tap(find.text('Bericht.pdf').last);
        await tester.pumpAndSettle();
        expect(attached, isNull, reason: 'schon angehängt');

        await tester.tap(find.text('Notiz.txt'));
        await tester.pumpAndSettle();

        expect(attached, _notiz);
        expect(find.byType(BottomSheet), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('Desktop: macOS-Sheet mit Abbrechen statt Bottom Sheet', (
      tester,
    ) async {
      NodeAttachment? attached;
      await tester.pumpWidget(
        _files(
          attached: const [],
          available: const [_bericht, _notiz],
          onAttach: (file) => attached = file,
        ),
      );

      await tester.tap(find.byTooltip('Datei anhängen'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Abbrechen'), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(attached, isNull);
      expect(find.text('Bericht.pdf'), findsNothing);

      await tester.tap(find.byTooltip('Datei anhängen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bericht.pdf'));
      await tester.pumpAndSettle();

      expect(attached, _bericht);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('zeigt einen Hinweis, wenn es keine Dateien gibt', (
      tester,
    ) async {
      await tester.pumpWidget(
        _files(attached: const [], available: const [], onAttach: (_) {}),
      );

      await tester.tap(find.byTooltip('Datei anhängen'));
      await tester.pumpAndSettle();

      expect(find.text('Noch keine Dateien hochgeladen.'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  group('Notizen anhängen', () {
    testWidgets('mobil: Bottom Sheet mit Titel und Pfad', (tester) async {
      KnowledgeAttachment? attached;
      await tester.pumpWidget(
        _notes(
          available: const [_wiki, _glossar],
          onAttach: (note) => attached = note,
        ),
      );

      await tester.tap(find.byTooltip('Notiz anhängen'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('projekte/plan.md'), findsOneWidget);
      await tester.tap(find.text('Glossar'));
      await tester.pumpAndSettle();

      expect(attached, _glossar);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('Desktop: Escape schließt das Sheet ohne Anhang', (
      tester,
    ) async {
      KnowledgeAttachment? attached;
      await tester.pumpWidget(
        _notes(available: const [_wiki], onAttach: (note) => attached = note),
      );

      await tester.tap(find.byTooltip('Notiz anhängen'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Abbrechen'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(attached, isNull);
      expect(find.text('Projektplan'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });
}
