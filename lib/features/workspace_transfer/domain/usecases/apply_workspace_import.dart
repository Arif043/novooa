import 'package:multiple_result/multiple_result.dart';

import '../entities/staged_transfer_import.dart';
import '../entities/transfer_category.dart';
import '../entities/transfer_counts.dart';
import '../entities/transfer_failure.dart';
import '../repositories/workspace_transfer_repository.dart';
import 'export_workspace_to_file.dart';

class ApplyWorkspaceImport {
  const ApplyWorkspaceImport(this._repository);

  final WorkspaceTransferRepository _repository;

  Future<Result<TransferCounts, TransferFailure>> call(
    TransferImportId id,
    Set<TransferCategory> categories,
  ) async {
    if (categories.isEmpty) return const Error(noSelectionFailure);
    return _repository.applyImport(id, categories);
  }
}
