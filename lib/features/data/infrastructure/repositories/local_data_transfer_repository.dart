import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_failure.dart';
import '../../domain/entities/data_file.dart';
import '../../domain/entities/data_import_preview.dart';
import '../../domain/entities/data_record_query.dart';
import '../../domain/repositories/data_transfer_repository.dart';
import 'data_failure_mapping.dart';
import 'data_json_reader.dart';
import 'data_request_json.dart';

class LocalDataTransferRepository implements DataTransferRepository {
  LocalDataTransferRepository(this._client);

  final WorkspaceBinaryClient _client;

  @override
  Future<Result<Uint8List, DataFailure>> export(
    DataCollection collection,
    DataFileFormat format,
    DataRecordQuery query,
  ) => dataResultOf(
    () => _client.postForBytes(
      '${dataCollectionPath(collection.name)}/export',
      {'format': format.name, ...dataQueryJson(query)},
    ),
  );

  @override
  Future<Result<DataImportPreview, DataFailure>> previewImport(
    DataCollection collection,
    DataFile file,
  ) => dataResultOf(() async {
    final response = await _upload(collection, file, dryRun: true);
    return _previewFrom(response);
  });

  @override
  Future<Result<int, DataFailure>> importRecords(
    DataCollection collection,
    DataFile file,
  ) => dataResultOf(() async {
    final response = await _upload(collection, file, dryRun: false);
    return jsonInt(response, 'imported');
  });

  Future<Map<String, Object?>> _upload(
    DataCollection collection,
    DataFile file, {
    required bool dryRun,
  }) {
    final format = file.format;
    if (format == null) throw const FormatException('Unbekanntes Dateiformat.');
    return _client.postBytes(
      '${dataCollectionPath(collection.name)}/import'
      '?format=${format.name}&dryRun=$dryRun',
      body: file.bytes,
      contentType: 'application/octet-stream',
    );
  }
}

DataImportPreview _previewFrom(Map<String, Object?> json) => DataImportPreview(
  count: jsonInt(json, 'count'),
  fields: _strings(json['fields']),
  renamedFields: [
    for (final item in jsonItems({'items': json['renamedFields']}))
      DataFieldRename(
        from: jsonString(jsonMap(item), 'from'),
        to: jsonString(jsonMap(item), 'to'),
      ),
  ],
  sample: [
    for (final item in jsonItems({'items': json['sample']})) jsonMap(item),
  ],
  issues: _strings(json['issues']),
);

List<String> _strings(Object? value) =>
    jsonItems({'items': value}).whereType<String>().toList(growable: false);
