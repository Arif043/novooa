import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/data/domain/entities/data_collection_name.dart';
import 'package:syscat2/features/data/domain/entities/data_failure.dart';
import 'package:syscat2/features/data/domain/entities/data_file.dart';
import 'package:syscat2/features/data/domain/entities/data_record_query.dart';
import 'package:syscat2/features/data/domain/entities/data_sort.dart';
import 'package:syscat2/features/data/infrastructure/repositories/local_data_collection_repository.dart';
import 'package:syscat2/features/data/infrastructure/repositories/local_data_transfer_repository.dart';

import '../support/data_test_fakes.dart';

void main() {
  final kunden = dataCollection('Kunden & Co');

  test('verwaltet Sammlungen ueber die Routen der Runtime', () async {
    final client = _ApiClient();
    final repository = LocalDataCollectionRepository(client);

    await repository.rename(kunden, DataCollectionName.tryParse('Partner')!);
    final cleared = await repository.clear(kunden);
    final deleted = await repository.deleteRecords(kunden, [
      dataRecord('a', {}),
    ]);

    expect(client.requests, [
      'PUT /v1/data/collections/Kunden%20%26%20Co {"name":"Partner"}',
      'DELETE /v1/data/collections/Kunden%20%26%20Co/documents',
      'POST /v1/data/collections/Kunden%20%26%20Co/documents/delete {"ids":["a"]}',
    ]);
    expect((cleared as Success).success, 4);
    expect((deleted as Success).success, 4);
  });

  test('uebersetzt einen belegten Namen in einen fachlichen Fehler', () async {
    final client = _ApiClient()..failWith = 409;

    final createdOrFailure = await LocalDataCollectionRepository(
      client,
    ).create(DataCollectionName.tryParse('Kunden')!);

    expect(
      (createdOrFailure as Error<Object, DataFailure>).error.kind,
      DataFailureKind.nameTaken,
    );
  });

  test('sendet Export-Abfrage und Importdatei im Format der Runtime', () async {
    final client = _BinaryClient();
    final repository = LocalDataTransferRepository(client);
    final file = DataFile(name: 'k.csv', bytes: Uint8List.fromList([1]));

    await repository.export(
      kunden,
      DataFileFormat.json,
      const DataRecordQuery(
        search: 'Ada',
        sort: DataSort(field: 'name', direction: DataSortDirection.descending),
      ),
    );
    final previewOrFailure = await repository.previewImport(kunden, file);
    await repository.importRecords(kunden, file);

    expect(client.requests, [
      'export {"format":"json","search":"Ada","filters":[],"sort":{"field":"name","direction":"desc"}}',
      'import ?format=csv&dryRun=true application/octet-stream',
      'import ?format=csv&dryRun=false application/octet-stream',
    ]);
    final preview = (previewOrFailure as Success).success;
    expect(preview.renamedFields.single.to, 'Kunden_Name');
    expect(preview.canImport, isTrue);
  });
}

class _ApiClient implements WorkspaceApiClient {
  final requests = <String>[];
  int? failWith;

  Future<Map<String, Object?>> _answer(String request) async {
    requests.add(request);
    if (failWith case final status?) {
      throw WorkspaceHttpException(
        status,
        const WorkspaceApiError(message: 'x'),
      );
    }
    return {
      'name': 'Partner',
      'documentCount': 0,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'deleted': 4,
    };
  }

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) =>
      _answer('POST $path ${jsonEncode(body)}');

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) =>
      _answer('PUT $path ${jsonEncode(body)}');

  @override
  Future<Map<String, Object?>> delete(String path) => _answer('DELETE $path');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BinaryClient implements WorkspaceBinaryClient {
  final requests = <String>[];

  @override
  Future<Uint8List> postForBytes(String path, Map<String, Object?> body) async {
    requests.add('${path.split('/').last} ${jsonEncode(body)}');
    return Uint8List(0);
  }

  @override
  Future<Map<String, Object?>> postBytes(
    String path, {
    required Uint8List body,
    required String contentType,
  }) async {
    requests.add('import ${path.substring(path.indexOf('?'))} $contentType');
    return {
      'count': 1,
      'imported': 1,
      'fields': ['Kunden_Name'],
      'renamedFields': [
        {'from': 'Kunden Name', 'to': 'Kunden_Name'},
      ],
      'sample': [
        {'Kunden_Name': 'Ada'},
      ],
      'issues': <Object>[],
    };
  }
}
