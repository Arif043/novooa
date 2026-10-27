import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_record.dart';

/// Liest die JSON-Antworten der Daten-Routen; jede Abweichung ist ein [FormatException].
DataCollection dataCollectionFromJson(Object? value) {
  final json = jsonMap(value);
  return DataCollection(
    name: jsonString(json, 'name'),
    documentCount: jsonInt(json, 'documentCount'),
    createdAt: DateTime.parse(jsonString(json, 'createdAt')),
    updatedAt: DateTime.parse(jsonString(json, 'updatedAt')),
  );
}

DataRecord dataRecordFromJson(Object? value) {
  final json = jsonMap(value);
  return DataRecord(
    id: jsonString(json, 'id'),
    fields: jsonMap(json['data']),
    createdAt: DateTime.parse(jsonString(json, 'createdAt')),
    updatedAt: DateTime.parse(jsonString(json, 'updatedAt')),
  );
}

List<Object?> jsonItems(Map<String, Object?> response) {
  final items = response['items'];
  if (items is! List) {
    throw const FormatException('Die Runtime lieferte keine Datenliste.');
  }
  return List<Object?>.from(items);
}

Map<String, Object?> jsonMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('Die Runtime lieferte ungültige Daten.');
  }
  return {for (final entry in value.entries) entry.key.toString(): entry.value};
}

String jsonString(Map<String, Object?> value, String key) {
  final item = value[key];
  if (item is! String) {
    throw const FormatException('Die Runtime lieferte ungültige Daten.');
  }
  return item;
}

int jsonInt(Map<String, Object?> value, String key) {
  final item = value[key];
  if (item is int) return item;
  if (item is num) return item.toInt();
  throw const FormatException('Die Runtime lieferte ungültige Daten.');
}
