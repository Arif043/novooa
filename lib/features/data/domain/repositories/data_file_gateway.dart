import 'package:multiple_result/multiple_result.dart';

import '../entities/data_failure.dart';
import '../entities/data_file.dart';

/// Dateien wählen und speichern — auf dem Desktop per Dialog, im Web als Download.
abstract interface class DataFileGateway {
  Future<Result<DataFile, DataFailure>> pickImportFile();

  Future<Result<Unit, DataFailure>> save(DataFile file);
}
