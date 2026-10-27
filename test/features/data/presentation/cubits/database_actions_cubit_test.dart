import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/data/domain/entities/data_collection_name.dart';
import 'package:syscat2/features/data/domain/entities/data_failure.dart';
import 'package:syscat2/features/data/domain/entities/data_file.dart';
import 'package:syscat2/features/data/domain/entities/data_record_query.dart';
import 'package:syscat2/features/data/domain/usecases/data_collections.dart';
import 'package:syscat2/features/data/domain/usecases/data_transfer.dart';
import 'package:syscat2/features/data/presentation/cubits/database_actions_cubit.dart';
import 'package:syscat2/features/data/presentation/cubits/database_actions_state.dart';

import '../../support/data_test_fakes.dart';

void main() {
  late FakeDataCollectionRepository collections;
  late FakeDataTransferRepository transfer;
  late FakeDataFileGateway files;
  late DatabaseActionsCubit cubit;
  final kunden = dataCollection('Kunden', count: 3);
  DataCollectionName name(String value) => DataCollectionName.tryParse(value)!;

  setUp(() {
    collections = FakeDataCollectionRepository();
    transfer = FakeDataTransferRepository();
    files = FakeDataFileGateway();
    cubit = DatabaseActionsCubit(
      create: CreateDataCollection(collections),
      rename: RenameDataCollection(collections),
      delete: DeleteDataCollection(collections),
      clear: ClearDataCollection(collections),
      deleteRecords: DeleteDataRecords(collections),
      exportRecords: ExportDataRecords(transfer, files),
    );
  });
  tearDown(() => cubit.close());

  test('legt eine Sammlung an und meldet sie', () async {
    final created = await cubit.createCollection(name('  Lieferanten '));

    expect(created?.name, 'Lieferanten');
    expect(cubit.state.notice?.kind, DatabaseNoticeKind.collectionCreated);
    expect(cubit.state.isBusy, isFalse);
  });

  test('meldet einen belegten Namen beim Umbenennen', () async {
    collections.failure = const DataFailure(DataFailureKind.nameTaken);

    final renamed = await cubit.renameCollection(kunden, name('Partner'));

    expect(renamed, isNull);
    expect(cubit.state.notice?.kind, DatabaseNoticeKind.failed);
    expect(cubit.state.notice?.failure?.kind, DataFailureKind.nameTaken);
  });

  test('leert und loescht Sammlungen und nennt Anzahl und Namen', () async {
    expect(await cubit.clearCollection(kunden), isTrue);
    final cleared = cubit.state.notice;
    expect(await cubit.deleteCollection(kunden), isTrue);

    expect(cleared?.count, 3);
    expect(cubit.state.notice?.kind, DatabaseNoticeKind.collectionDeleted);
    expect(collections.calls, ['clear Kunden', 'delete Kunden']);
  });

  test(
    'loescht nur ausgewaehlte Datensaetze und ruft ohne Auswahl nichts auf',
    () async {
      final records = [dataRecord('a', {}), dataRecord('b', {})];

      expect(await cubit.deleteRecords(kunden, records), isTrue);
      expect(await cubit.deleteRecords(kunden, const []), isTrue);

      expect(collections.calls, ['deleteRecords a,b']);
      expect(cubit.state.notice?.count, 0);
    },
  );

  test(
    'exportiert mit der aktuellen Abfrage unter dem Sammlungsnamen',
    () async {
      const query = DataRecordQuery(search: 'Ada');

      await cubit.export(kunden, DataFileFormat.csv, query);

      expect(transfer.lastExportQuery, query);
      expect(files.saved?.name, 'Kunden.csv');
      expect(cubit.state.notice?.kind, DatabaseNoticeKind.exported);
    },
  );

  test('meldet nichts, wenn das Speichern abgebrochen wird', () async {
    files.saveResult = const Error(DataFailure(DataFailureKind.cancelled));

    await cubit.export(kunden, DataFileFormat.json, const DataRecordQuery());

    expect(cubit.state.notice, isNull);
    expect(cubit.state.isBusy, isFalse);
  });

  test('meldet einen abgeschlossenen Import', () {
    cubit.reportImported(12);

    expect(cubit.state.notice?.kind, DatabaseNoticeKind.recordsImported);
    expect(cubit.state.notice?.count, 12);
  });
}
