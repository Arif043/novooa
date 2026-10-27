import 'package:multiple_result/multiple_result.dart';

import '../entities/data_collection.dart';
import '../entities/data_failure.dart';
import '../entities/data_file.dart';
import '../entities/data_import_preview.dart';
import '../entities/data_record_query.dart';
import '../repositories/data_file_gateway.dart';
import '../repositories/data_transfer_repository.dart';

/// Lädt alle Treffer als Datei aus der Runtime und speichert sie als `<Sammlung>.<format>`.
class ExportDataRecords {
  const ExportDataRecords(this._repository, this._files);

  final DataTransferRepository _repository;
  final DataFileGateway _files;

  Future<Result<Unit, DataFailure>> call(
    DataCollection collection,
    DataFileFormat format,
    DataRecordQuery query,
  ) async {
    final bytesOrFailure = await _repository.export(collection, format, query);
    return switch (bytesOrFailure) {
      Success(success: final bytes) => _files.save(
        DataFile(name: '${collection.name}.${format.extension}', bytes: bytes),
      ),
      Error(error: final failure) => Error(failure),
    };
  }
}

/// Wählt eine Importdatei und prüft vorab Format und Größe — vor jedem Upload.
class PickDataImportFile {
  const PickDataImportFile(this._files);

  final DataFileGateway _files;

  Future<Result<DataFile, DataFailure>> call() async {
    final fileOrFailure = await _files.pickImportFile();
    return switch (fileOrFailure) {
      Success(success: final file) when file.format == null => const Error(
        DataFailure(DataFailureKind.invalidFile),
      ),
      Success(success: final file) when file.isTooLargeForImport => const Error(
        DataFailure(DataFailureKind.tooLarge),
      ),
      _ => fileOrFailure,
    };
  }
}

class PreviewDataImport {
  const PreviewDataImport(this._repository);

  final DataTransferRepository _repository;

  Future<Result<DataImportPreview, DataFailure>> call(
    DataCollection collection,
    DataFile file,
  ) => _repository.previewImport(collection, file);
}

class ImportDataRecords {
  const ImportDataRecords(this._repository);

  final DataTransferRepository _repository;

  Future<Result<int, DataFailure>> call(
    DataCollection collection,
    DataFile file,
  ) => _repository.importRecords(collection, file);
}
