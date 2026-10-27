import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/data/domain/entities/data_failure.dart';
import 'package:syscat2/features/data/domain/entities/data_file.dart';
import 'package:syscat2/features/data/domain/entities/data_import_preview.dart';
import 'package:syscat2/features/data/domain/usecases/data_transfer.dart';
import 'package:syscat2/features/data/presentation/cubits/database_import_cubit.dart';
import 'package:syscat2/features/data/presentation/cubits/database_import_state.dart';

import '../../support/data_test_fakes.dart';

void main() {
  late FakeDataTransferRepository transfer;
  late FakeDataFileGateway files;
  late DatabaseImportCubit cubit;

  setUp(() {
    transfer = FakeDataTransferRepository();
    files = FakeDataFileGateway();
    cubit = DatabaseImportCubit(
      collection: dataCollection('Kunden'),
      pickFile: PickDataImportFile(files),
      preview: PreviewDataImport(transfer),
      importRecords: ImportDataRecords(transfer),
    );
  });
  tearDown(() => cubit.close());

  test('zeigt erst die Vorschau und uebernimmt nach Bestaetigung', () async {
    await cubit.start();
    final preview = cubit.state;
    await cubit.confirm();

    expect(preview.step, DatabaseImportStep.preview);
    expect(preview.file?.name, 'kunden.csv');
    expect(cubit.state.step, DatabaseImportStep.done);
    expect(cubit.state.importedCount, 2);
  });

  test('uebernimmt nichts, solange die Datei Probleme hat', () async {
    transfer.preview = const DataImportPreview(
      count: 1,
      fields: ['n'],
      renamedFields: [],
      sample: [],
      issues: ['Zeile 2: mehr Werte als Spalten in der Kopfzeile.'],
    );
    await cubit.start();
    await cubit.confirm();

    expect(cubit.state.step, DatabaseImportStep.preview);
    expect(transfer.imported, 0);
  });

  test('beendet sich still, wenn keine Datei gewaehlt wird', () async {
    files.picked = const Error(DataFailure(DataFailureKind.cancelled));

    await cubit.start();

    expect(cubit.state.step, DatabaseImportStep.cancelled);
  });

  test(
    'weist fremde Formate und zu grosse Dateien vor dem Upload ab',
    () async {
      files.picked = Success(
        DataFile(name: 'kunden.xlsx', bytes: Uint8List(1)),
      );
      await cubit.start();
      final foreign = cubit.state.failure?.kind;
      files.picked = Success(
        DataFile(
          name: 'gross.csv',
          bytes: Uint8List(DataFile.maximumImportBytes + 1),
        ),
      );
      await cubit.start();

      expect(foreign, DataFailureKind.invalidFile);
      expect(cubit.state.step, DatabaseImportStep.failed);
      expect(cubit.state.failure?.kind, DataFailureKind.tooLarge);
    },
  );
}
