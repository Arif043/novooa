import 'package:multiple_result/multiple_result.dart';

import '../entities/data_collection.dart';
import '../entities/data_collection_name.dart';
import '../entities/data_failure.dart';
import '../entities/data_record.dart';

/// Sammlungen von Hand verwalten und ihren Inhalt in einem Schritt löschen.
abstract interface class DataCollectionRepository {
  Future<Result<DataCollection, DataFailure>> create(DataCollectionName name);

  Future<Result<DataCollection, DataFailure>> rename(
    DataCollection collection,
    DataCollectionName name,
  );

  /// Löscht die Sammlung samt allen Datensätzen.
  Future<Result<Unit, DataFailure>> delete(DataCollection collection);

  /// Löscht alle Datensätze; die Sammlung bleibt. Liefert die Anzahl.
  Future<Result<int, DataFailure>> clear(DataCollection collection);

  /// Löscht die gewählten Datensätze; liefert die Anzahl.
  Future<Result<int, DataFailure>> deleteRecords(
    DataCollection collection,
    List<DataRecord> records,
  );
}
