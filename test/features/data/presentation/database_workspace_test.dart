import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/data/domain/entities/data_collection.dart';
import 'package:syscat2/features/data/domain/entities/data_record.dart';
import 'package:syscat2/features/data/domain/entities/data_filter.dart';
import 'package:syscat2/features/data/presentation/cubits/database_cubit.dart';
import 'package:syscat2/features/data/presentation/cubits/database_state.dart';
import 'package:syscat2/features/data/presentation/pages/database_page.dart';
import 'package:syscat2/features/data/presentation/widgets/database_sheet.dart';
import 'package:syscat2/features/data/presentation/widgets/database_record_editor_dialog.dart';

final collection = DataCollection(
  name: 'Kunden',
  documentCount: 50,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
final records = List.generate(
  50,
  (i) => DataRecord(
    id: 'internal-$i',
    fields: {
      'name': 'Person $i',
      'umsatz': i * 10,
      'aktiv': true,
      'details': {'ort': 'Berlin'},
    },
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
);

class _Cubit extends Cubit<DatabaseState> implements DatabaseCubit {
  _Cubit({bool overview = false})
    : super(
        DatabaseState(
          status: overview
              ? DatabaseStatus.collections
              : DatabaseStatus.records,
          collections: [collection],
          collection: overview ? null : collection,
          records: records,
        ),
      );
  Map<String, Object?>? created;
  Map<String, Object?>? updated;
  DataRecord? deleted;
  @override
  Future<void> openCollection(DataCollection value) async =>
      emit(state.copyWith(status: DatabaseStatus.records, collection: value));
  @override
  Future<void> showCollections() async => emit(
    state.copyWith(status: DatabaseStatus.collections, clearCollection: true),
  );
  @override
  Future<void> search(String value) async =>
      emit(state.copyWith(search: value));
  @override
  void addFilter() => emit(
    state.copyWith(
      filters: [
        const DataFilter(
          field: '',
          operator: DataFilterOperator.equals,
          value: '',
        ),
      ],
    ),
  );
  @override
  Future<void> removeFilter(int index) async =>
      emit(state.copyWith(filters: []));
  @override
  Future<void> createRecord(Map<String, Object?> fields) async {
    created = fields;
  }

  @override
  Future<void> updateRecord(
    DataRecord record,
    Map<String, Object?> fields,
  ) async {
    updated = fields;
  }

  @override
  Future<void> deleteRecord(DataRecord record) async {
    deleted = record;
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
    body: BlocProvider<DatabaseCubit>.value(
      value: cubit,
      child: const DatabaseView(),
    ),
  ),
);

void main() {
  if (const bool.fromEnvironment('CAPTURE_DATABASE')) {
    testWidgets('capture database sheet', (tester) async {
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
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final cubit = _Cubit();
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: _app(cubit)));
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/tmp/novooa-database.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    });
  }
  testWidgets(
    'sheet fits small, landscape and desktop windows with large text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in [
        const Size(375, 812),
        const Size(812, 375),
        const Size(1400, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        for (final dark in [false, true]) {
          final cubit = _Cubit();
          await tester.pumpWidget(_app(cubit, dark: dark, scale: 2));
          await tester.pumpAndSettle();
          expect(find.byType(DatabaseSheet), findsOneWidget);
          await tester.ensureVisible(find.text('Filter hinzufügen'));
          await tester.tap(find.text('Filter hinzufügen'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await cubit.close();
        }
      }
    },
  );

  testWidgets(
    'collection opening, search, edit, create and delete retain their callbacks',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = _Cubit(overview: true);
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kunden'));
      await tester.pumpAndSettle();
      expect(find.text('internal-0'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Suchen'),
        'Person',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(cubit.state.search, 'Person');
      await tester.tap(find.text('Person 0'));
      await tester.pumpAndSettle();
      expect(find.byType(DatabaseRecordEditorDialog), findsOneWidget);
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(cubit.updated, records.first.fields);
      await tester.tap(find.text('Datensatz anlegen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Feld'), 'anzahl');
      await tester.enterText(find.widgetWithText(TextField, 'Wert'), '42');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(cubit.created, {'anzahl': 42});
      await tester.tap(find.byTooltip('Datensatz löschen').first);
      await tester.pumpAndSettle();
      expect(cubit.deleted, isNull);
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(cubit.deleted, records.first);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );

  testWidgets('column header stays visible while scrolling records', (
    tester,
  ) async {
    final cubit = _Cubit();
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text('aktiv'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('aktiv')), before);
    expect(find.text('Person 0'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
