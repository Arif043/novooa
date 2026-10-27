import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/data/domain/entities/data_sort.dart';
import 'package:syscat2/features/data/domain/usecases/data_records.dart';
import 'package:syscat2/features/data/presentation/cubits/database_cubit.dart';
import 'package:syscat2/features/data/presentation/pages/database_page.dart';

import '../support/data_test_fakes.dart';
import 'database_test_providers.dart';

final _dialogField = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

void main() {
  late FakeDataRepository records;
  late FakeDataCollectionRepository collections;
  late DatabaseCubit cubit;

  setUp(() {
    records = FakeDataRepository()
      ..records.addAll([
        dataRecord('a', {'name': 'Ada', 'umsatz': 5}),
        dataRecord('b', {'name': 'Ben', 'umsatz': 20}),
      ]);
    collections = FakeDataCollectionRepository();
    cubit = DatabaseCubit(
      listCollections: ListDataCollections(records),
      queryRecords: QueryDataRecords(records),
      createRecord: CreateDataRecord(records),
      updateRecord: UpdateDataRecord(records),
      deleteRecord: DeleteDataRecord(records),
    );
  });
  tearDown(() => cubit.close());

  Future<void> pumpPage(WidgetTester tester, {bool open = true}) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await cubit.loadCollections();
    if (open) await cubit.openCollection(records.collection);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: databaseTestProviders(
            cubit: cubit,
            collections: collections,
            child: const DatabaseView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Aktionen für „Kunden“'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('sortiert per Klick auf den Spaltenkopf und zeigt die Richtung', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('umsatz'));
    await tester.pumpAndSettle();

    expect(records.lastSort?.field, 'umsatz');
    expect(records.lastSort?.direction, DataSortDirection.ascending);
    expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);
  });

  testWidgets('loescht ausgewaehlte Datensaetze nach Rueckfrage', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(find.text('1 ausgewählt'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pumpAndSettle();
    expect(find.text('1 Datensätze löschen?'), findsOneWidget);
    await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Löschen'));
    await tester.pumpAndSettle();

    expect(collections.calls, ['deleteRecords a']);
    expect(find.text('1 Datensätze gelöscht.'), findsOneWidget);
  });

  testWidgets('benennt die geoeffnete Sammlung um und warnt vor Bausteinen', (
    tester,
  ) async {
    await pumpPage(tester);

    await chooseMenu(tester, 'Umbenennen …');
    expect(
      find.textContaining('Bausteine, die den alten Namen'),
      findsOneWidget,
    );
    await tester.enterText(_dialogField, 'Partner');
    await tester.tap(find.widgetWithText(FilledButton, 'Umbenennen'));
    await tester.pumpAndSettle();

    expect(collections.calls, ['rename Kunden → Partner']);
    expect(find.text('Umbenannt in „Partner“.'), findsOneWidget);
  });

  testWidgets('loescht die Sammlung und kehrt zur Uebersicht zurueck', (
    tester,
  ) async {
    await pumpPage(tester);

    await chooseMenu(tester, 'Sammlung löschen …');
    expect(find.text('„Kunden“ löschen?'), findsOneWidget);
    await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Löschen'));
    await tester.pumpAndSettle();

    expect(collections.calls, ['delete Kunden']);
    expect(find.text('Datensammlungen'), findsOneWidget);
  });

  testWidgets('legt in der Uebersicht eine Sammlung an und prueft den Namen', (
    tester,
  ) async {
    await pumpPage(tester, open: false);

    await tester.tap(find.text('Sammlung anlegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Anlegen'));
    await tester.pumpAndSettle();
    expect(find.text('Gib einen Namen ein.'), findsOneWidget);
    await tester.enterText(_dialogField, 'Lieferanten');
    await tester.tap(find.widgetWithText(FilledButton, 'Anlegen'));
    await tester.pumpAndSettle();

    expect(collections.calls, ['create Lieferanten']);
  });

  testWidgets('importiert nach Vorschau und meldet die Anzahl', (tester) async {
    await pumpPage(tester);

    await chooseMenu(tester, 'Importieren …');
    expect(find.text('2 Datensätze aus „kunden.csv“'), findsOneWidget);
    await tester.tap(find.text('2 Datensätze übernehmen'));
    await tester.pumpAndSettle();

    expect(find.text('2 Datensätze importiert.'), findsOneWidget);
  });
}
