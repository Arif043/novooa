import 'package:multiple_result/multiple_result.dart';

import '../entities/staged_transfer_import.dart';
import '../entities/transfer_failure.dart';
import '../repositories/transfer_file_gateway.dart';
import '../repositories/workspace_transfer_repository.dart';

/// Lässt eine Export-Datei auswählen und lädt sie zur Prüfung hoch.
class StageWorkspaceImport {
  const StageWorkspaceImport(this._repository, this._files);

  final WorkspaceTransferRepository _repository;
  final TransferFileGateway _files;

  Future<Result<StagedTransferImport, TransferFailure>> call() async {
    final archiveOrFailure = await _files.pick();
    return switch (archiveOrFailure) {
      Success(success: final archive) => _repository.stageImport(archive),
      Error(error: final failure) => Error(failure),
    };
  }
}
