import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_state.dart';
import 'package:syscat2/features/knowledge_base/presentation/pages/knowledge_base_page.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_base_editor.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_base_graph_view.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_markdown_preview.dart';

final _notes = [
  KnowledgeNote(
    id: 'one',
    knowledgeBaseId: 'default',
    title: 'Projektwissen',
    path: 'projektwissen.md',
    content: '# Projektwissen\nSiehe [[Leitfaden]].',
    outgoingLinks: ['two'],
    updatedAt: DateTime(2026),
  ),
  KnowledgeNote(
    id: 'two',
    knowledgeBaseId: 'default',
    title: 'Leitfaden',
    path: 'leitfaden.md',
    content: 'Unser gemeinsames Wissen.',
    outgoingLinks: [],
    updatedAt: DateTime(2026),
  ),
];

class _Cubit extends Cubit<KnowledgeBaseState> implements KnowledgeBaseCubit {
  _Cubit({bool empty = false})
    : super(
        KnowledgeBaseState(
          status: KnowledgeBaseStatus.ready,
          notes: empty ? [] : _notes,
          selectedNoteId: empty ? null : 'one',
        ),
      );
  bool deleted = false;
  @override
  void selectNote(String id) => emit(state.copyWith(selectedNoteId: id));
  @override
  void setQuery(String query) => emit(state.copyWith(query: query));
  @override
  void updateTitle(String value) => emit(
    state.copyWith(
      notes: state.notes
          .map(
            (n) =>
                n.id == state.selectedNote!.id ? n.copyWith(title: value) : n,
          )
          .toList(),
      isSaving: true,
    ),
  );
  @override
  void updateContent(String value) => emit(
    state.copyWith(
      notes: state.notes
          .map(
            (n) =>
                n.id == state.selectedNote!.id ? n.copyWith(content: value) : n,
          )
          .toList(),
      isSaving: true,
    ),
  );
  @override
  Future<void> createNote() async =>
      emit(state.copyWith(notes: _notes, selectedNoteId: 'one'));
  @override
  Future<void> deleteSelected() async {
    deleted = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_Cubit cubit, {bool dark = false, double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: dark ? SyscatTheme.darkTheme : SyscatTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(
    body: BlocProvider<KnowledgeBaseCubit>.value(
      value: cubit,
      child: const KnowledgeBaseView(),
    ),
  ),
);

void main() {
  if (const bool.fromEnvironment('CAPTURE_KNOWLEDGE')) {
    testWidgets('capture knowledge workspace', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        final path = Platform.environment['WORKSPACE_PREVIEW_FONT'];
        if (path != null) {
          final bytes = await File(path).readAsBytes();
          await (FontLoader(
            'Inter',
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        }
        await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
              rootBundle.load(
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
              ),
            ))
            .load();
      });
      final cubit = _Cubit();
      final key = GlobalKey();
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _app(cubit, dark: dark),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/tmp/novooa-knowledge-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    });
  }
  testWidgets('responsive notebook supports large text and both themes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [
      const Size(375, 812),
      const Size(812, 375),
      const Size(1280, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      for (final dark in [false, true]) {
        final cubit = _Cubit();
        await tester.pumpWidget(_app(cubit, dark: dark, scale: 2));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Projektwissen').first);
        await tester.pumpAndSettle();
        expect(find.byType(KnowledgeBaseEditor), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await cubit.close();
      }
    }
  });

  testWidgets(
    'search, note selection, editing, modes and delete confirmation work',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = _Cubit();
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notizen durchsuchen'),
        'Leitfaden',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Leitfaden'));
      await tester.pumpAndSettle();
      expect(cubit.state.selectedNote!.id, 'two');
      await tester.enterText(
        find.widgetWithText(TextField, 'Notizinhalt'),
        'Neuer Inhalt',
      );
      await tester.pumpAndSettle();
      expect(cubit.state.selectedNote!.content, 'Neuer Inhalt');
      expect(find.text('Wird gespeichert …'), findsOneWidget);
      await tester.tap(find.byTooltip('Lesen'));
      await tester.pumpAndSettle();
      expect(find.byType(KnowledgeMarkdownPreview), findsOneWidget);
      await tester.tap(find.byTooltip('Graph'));
      await tester.pumpAndSettle();
      expect(find.byType(KnowledgeBaseGraphView), findsOneWidget);
      await tester.tap(find.byTooltip('Notiz löschen'));
      await tester.pumpAndSettle();
      expect(cubit.deleted, false);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(cubit.deleted, false);
      await tester.tap(find.byTooltip('Notiz löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(cubit.deleted, true);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );

  testWidgets('empty notebook can create first note', (tester) async {
    final cubit = _Cubit(empty: true);
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erste Notiz erstellen'));
    await tester.pumpAndSettle();
    expect(cubit.state.notes, isNotEmpty);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
