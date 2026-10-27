import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/data/domain/entities/data_collection_name.dart';
import 'package:syscat2/features/data/domain/entities/data_file.dart';
import 'package:syscat2/features/data/domain/entities/data_sort.dart';

void main() {
  test('Sammlungsnamen werden getrimmt und begrenzt', () {
    expect(DataCollectionName.tryParse('  Kunden ')?.value, 'Kunden');
    expect(DataCollectionName.issueOf('   '), DataCollectionNameIssue.empty);
    expect(
      DataCollectionName.issueOf('x' * (DataCollectionName.maximumLength + 1)),
      DataCollectionNameIssue.tooLong,
    );
  });

  test('ein Spaltenklick wechselt auf-, absteigend und aus', () {
    final ascending = DataSort.toggled(null, 'umsatz');
    final descending = DataSort.toggled(ascending, 'umsatz');
    final other = DataSort.toggled(descending, 'name');

    expect(ascending?.direction, DataSortDirection.ascending);
    expect(descending?.direction, DataSortDirection.descending);
    expect(DataSort.toggled(descending, 'umsatz'), isNull);
    expect(
      other,
      const DataSort(field: 'name', direction: DataSortDirection.ascending),
    );
  });

  test('nur Feldnamen ohne Pfad und Sonderzeichen sind sortierbar', () {
    expect(DataSort.isSortable('kunden_name'), isTrue);
    expect(DataSort.isSortable('Kunden Name'), isFalse);
    expect(DataSort.isSortable('adresse.ort'), isFalse);
  });

  test(
    'das Format folgt der Dateiendung ohne Ruecksicht auf Gross-/Kleinschreibung',
    () {
      expect(DataFileFormat.ofFileName('Kunden.CSV'), DataFileFormat.csv);
      expect(DataFileFormat.ofFileName('export.json'), DataFileFormat.json);
      expect(DataFileFormat.ofFileName('tabelle.xlsx'), isNull);
    },
  );
}
