import '../entities/staged_transfer_import.dart';
import '../repositories/workspace_transfer_repository.dart';

class DiscardWorkspaceImport {
  const DiscardWorkspaceImport(this._repository);

  final WorkspaceTransferRepository _repository;

  Future<void> call(TransferImportId id) => _repository.discardImport(id);
}
