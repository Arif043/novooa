import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:syscat2/core/widgets/luminous_card.dart';
import 'package:syscat2/features/data/domain/entities/data_collection.dart';
import 'package:syscat2/features/data/domain/usecases/data_records.dart';
import 'package:syscat2/features/data/presentation/cubits/database_cubit.dart';
import 'package:syscat2/features/data/presentation/pages/database_page.dart';
import 'package:syscat2/features/data/presentation/widgets/database_labels.dart';

import '../support/data_test_fakes.dart';
import 'database_test_providers.dart';

void main() {
  testWidgets('zeigt Sammlungen als Karten mit Feldern, Anzahl und Suche', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeDataRepository()
      ..collections = [
        _collection('Kunden', 124, ['email', 'name', 'ort', 'plz', 'umsatz']),
        _collection('Bestellungen', 1, const []),
      ];
    final cubit = DatabaseCubit(
      listCollections: ListDataCollections(repository),
      queryRecords: QueryDataRecords(repository),
      createRecord: CreateDataRecord(repository),
      updateRecord: UpdateDataRecord(repository),
      deleteRecord: DeleteDataRecord(repository),
    );
    addTearDown(cubit.close);
    await cubit.loadCollections();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: databaseTestProviders(
            cubit: cubit,
            child: const DatabaseView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Datenbank'), findsOneWidget);
    expect(find.text('2 Sammlungen · 125 Datensätze'), findsOneWidget);
    expect(find.byType(LuminousCard), findsNWidgets(2));
    expect(find.text('email · name · ort · plz · +1'), findsOneWidget);
    expect(find.text('Noch keine Felder'), findsOneWidget);
    expect(find.textContaining('1 Datensatz ·'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'umsatz');
    await tester.pumpAndSettle();
    expect(
      find.byType(LuminousCard),
      findsOneWidget,
      reason: 'Feldnamen zählen',
    );
    await tester.enterText(find.byType(TextField), 'lager');
    await tester.pumpAndSettle();
    expect(find.text('Keine Sammlung passt zu „lager“.'), findsOneWidget);
  });

  test(
    'nennt die letzte Aenderung relativ und ab einer Woche mit Datum',
    () async {
      // Die App bekommt die Datumsdaten über flutter_localizations, der Unit-Test nicht.
      await initializeDateFormatting('de');
      final now = DateTime(2026, 10, 27, 12);
      String label(Duration age) =>
          databaseChangedLabel(now.subtract(age), now, 'de');

      expect(label(const Duration(seconds: 20)), 'gerade geändert');
      expect(label(const Duration(minutes: 5)), 'geändert vor 5 Min.');
      expect(label(const Duration(hours: 2)), 'geändert vor 2 Std.');
      expect(label(const Duration(days: 3)), 'geändert vor 3 Tagen');
      expect(label(const Duration(days: 10)), 'geändert am 17.10.2026');
    },
  );
}

DataCollection _collection(String name, int count, List<String> fields) =>
    DataCollection(
      name: name,
      documentCount: count,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      fields: fields,
      changedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
