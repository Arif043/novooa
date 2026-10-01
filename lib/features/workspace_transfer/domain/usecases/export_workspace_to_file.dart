import 'package:multiple_result/multiple_result.dart';

import '../entities/transfer_category.dart';
import '../entities/transfer_failure.dart';
import '../repositories/transfer_file_gateway.dart';
import '../repositories/workspace_transfer_repository.dart';

class ExportWorkspaceToFile {
  const ExportWorkspaceToFile(this._repository, this._files);

  final WorkspaceTransferRepository _repository;
  final TransferFileGateway _files;

  Future<Result<Unit, TransferFailure>> call(
    Set<TransferCategory> categories,
  ) async {
    if (categories.isEmpty) return const Error(noSelectionFailure);
    final archiveOrFailure = await _repository.exportArchive(categories);
    return switch (archiveOrFailure) {
      Success(success: final archive) => _files.save(archive),
      Error(error: final failure) => Error(failure),
    };
  }
}

const noSelectionFailure = TransferFailure(
  TransferFailureKind.failed,
  'Bitte wähle mindestens einen Bereich aus.',
);
