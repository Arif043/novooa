import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/data/domain/entities/data_filter.dart';
import 'package:syscat2/features/data/domain/entities/data_sort.dart';
import 'package:syscat2/features/data/domain/usecases/data_records.dart';
import 'package:syscat2/features/data/presentation/cubits/database_cubit.dart';

import '../../support/data_test_fakes.dart';

void main() {
  test('legt, aktualisiert und loescht Datensaetze ueber den Cubit', () async {
    final repository = FakeDataRepository();
    final cubit = _cubit(repository);
    await cubit.loadCollections();
    await cubit.openCollection(repository.collection);

    await cubit.createRecord({'name': 'Ada'});
    final created = repository.records.single;
    await cubit.updateRecord(created, {'name': 'Grace'});
    await cubit.deleteRecord(repository.records.single);

    expect(repository.createdFields, {'name': 'Ada'});
    expect(repository.updatedFields, {'name': 'Grace'});
    expect(repository.records, isEmpty);
    await cubit.close();
  });

  test('wendet Suche und Filter auf die Abfrage an', () async {
    final repository = FakeDataRepository();
    final cubit = _cubit(repository);
    await cubit.openCollection(repository.collection);
    cubit.addFilter();
    await cubit.changeFilter(
      0,
      const DataFilter(
        field: 'status',
        operator: DataFilterOperator.equals,
        value: 'offen',
      ),
    );
    await cubit.search('Ada');

    expect(repository.lastSearch, 'Ada');
    expect(repository.lastFilters.single.field, 'status');
    await cubit.close();
  });

  test('sortiert auf-, dann absteigend, dann gar nicht', () async {
    final repository = FakeDataRepository();
    final cubit = _cubit(repository);
    await cubit.openCollection(repository.collection);

    await cubit.toggleSort('umsatz');
    final ascending = repository.lastSort;
    await cubit.toggleSort('umsatz');
    final descending = repository.lastSort;
    await cubit.toggleSort('umsatz');
    await cubit.toggleSort('Kunden Name');

    expect(ascending?.direction, DataSortDirection.ascending);
    expect(descending?.direction, DataSortDirection.descending);
    expect(
      repository.lastSort,
      isNull,
      reason: 'ungültige Felder sind nicht sortierbar',
    );
    await cubit.close();
  });

  test(
    'waehlt Datensaetze aus und vergisst geloeschte beim Neuladen',
    () async {
      final repository = FakeDataRepository()
        ..records.addAll([dataRecord('a', {}), dataRecord('b', {})]);
      final cubit = _cubit(repository);
      await cubit.openCollection(repository.collection);

      cubit.toggleSelection(repository.records.first);
      final one = cubit.state.selectedIds;
      cubit.toggleAllSelected();
      final all = cubit.state.selectedIds;
      repository.records.removeAt(0);
      await cubit.reload();

      expect(one, {'a'});
      expect(all, {'a', 'b'});
      expect(cubit.state.selectedIds, {'b'});
      // Alle sichtbaren sind gewählt: Ein weiterer Klick hebt die Auswahl auf.
      cubit.toggleAllSelected();
      expect(cubit.state.selectedIds, isEmpty);
      await cubit.close();
    },
  );

  test(
    'oeffnet nach dem Neuladen die genannte Sammlung mit frischer Anzahl',
    () async {
      final repository = FakeDataRepository();
      final cubit = _cubit(repository);
      await cubit.openCollection(repository.collection);
      repository.collections = [dataCollection('Kundschaft', count: 7)];

      await cubit.reload(collection: dataCollection('Kundschaft'));

      expect(cubit.state.collection?.documentCount, 7);
      await cubit.close();
    },
  );
}

DatabaseCubit _cubit(FakeDataRepository repository) => DatabaseCubit(
  listCollections: ListDataCollections(repository),
  queryRecords: QueryDataRecords(repository),
  createRecord: CreateDataRecord(repository),
  updateRecord: UpdateDataRecord(repository),
  deleteRecord: DeleteDataRecord(repository),
);
