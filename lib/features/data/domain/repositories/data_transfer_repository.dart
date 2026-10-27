import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';

import '../entities/data_collection.dart';
import '../entities/data_failure.dart';
import '../entities/data_file.dart';
import '../entities/data_import_preview.dart';
import '../entities/data_record_query.dart';

/// Datensätze als Datei austauschen; Lesen und Schreiben der Formate übernimmt die Runtime.
abstract interface class DataTransferRepository {
  /// Alle Treffer der Abfrage — nicht nur die in der Ansicht geladenen.
  Future<Result<Uint8List, DataFailure>> export(
    DataCollection collection,
    DataFileFormat format,
    DataRecordQuery query,
  );

  Future<Result<DataImportPreview, DataFailure>> previewImport(
    DataCollection collection,
    DataFile file,
  );

  /// Hängt alle Datensätze der Datei an; liefert die Anzahl.
  Future<Result<int, DataFailure>> importRecords(
    DataCollection collection,
    DataFile file,
  );
}
