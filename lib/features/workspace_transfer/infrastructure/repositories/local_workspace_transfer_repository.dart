import 'dart:async';

import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../../../core/logging/logger.dart';
import '../../domain/entities/staged_transfer_import.dart';
import '../../domain/entities/transfer_archive.dart';
import '../../domain/entities/transfer_category.dart';
import '../../domain/entities/transfer_counts.dart';
import '../../domain/entities/transfer_failure.dart';
import '../../domain/repositories/workspace_transfer_repository.dart';
import '../models/transfer_response_model.dart';

class LocalWorkspaceTransferRepository implements WorkspaceTransferRepository {
  const LocalWorkspaceTransferRepository(this._client, this._binaryClient);

  final WorkspaceApiClient _client;
  final WorkspaceBinaryClient _binaryClient;

  @override
  Future<Result<TransferArchive, TransferFailure>> exportArchive(
    Set<TransferCategory> categories,
  ) => _attempt(() async {
    final bytes = await _binaryClient.postForBytes(
      '/v1/transfer/export',
      _selection(categories),
    );
    final fileName = TransferArchive.fileNameFor(DateTime.now());
    return TransferArchive(fileName: fileName, bytes: bytes);
  });

  @override
  Future<Result<StagedTransferImport, TransferFailure>> stageImport(
    TransferArchive archive,
  ) => _attempt(() async {
    final response = await _binaryClient.postBytes(
      '/v1/transfer/imports',
      body: archive.bytes,
      contentType: 'application/zip',
    );
    return TransferResponseModel.stagedImportFrom(response);
  });

  @override
  Future<Result<TransferCounts, TransferFailure>> applyImport(
    TransferImportId id,
    Set<TransferCategory> categories,
  ) => _attempt(() async {
    final response = await _client.post(
      '/v1/transfer/imports/${Uri.encodeComponent(id.value)}/apply',
      _selection(categories),
    );
    return TransferResponseModel.importedFrom(response);
  });

  @override
  Future<void> discardImport(TransferImportId id) async {
    try {
      await _client.delete(
        '/v1/transfer/imports/${Uri.encodeComponent(id.value)}',
      );
    } on Object catch (error, stackTrace) {
      // Nicht übernommene Uploads verfallen in der Runtime ohnehin.
      logException(
        message: 'Import konnte nicht verworfen werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'transfer',
      );
    }
  }

  Map<String, Object?> _selection(Set<TransferCategory> categories) => {
    'categories': [for (final category in categories) category.apiName],
  };

  Future<Result<T, TransferFailure>> _attempt<T extends Object>(
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } on Object catch (error) {
      return Error(_failureFrom(error));
    }
  }
}

TransferFailure _failureFrom(Object error) =>
    TransferFailure(TransferFailureKind.failed, switch (error) {
      WorkspaceHttpException(:final message) => message,
      WorkspaceConnectionException() => 'Die Runtime ist nicht erreichbar.',
      TimeoutException() => 'Die Runtime hat nicht rechtzeitig geantwortet.',
      _ => 'Die Antwort der Runtime war ungültig.',
    });
