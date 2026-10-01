import '../../domain/entities/staged_transfer_import.dart';
import '../../domain/entities/transfer_category.dart';
import '../../domain/entities/transfer_counts.dart';

sealed class WorkspaceImportState {
  const WorkspaceImportState();
}

final class ImportIdle extends WorkspaceImportState {
  const ImportIdle();
}

final class ImportUploading extends WorkspaceImportState {
  const ImportUploading();
}

/// Datei ist geprüft; Nutzer:innen wählen die zu übernehmenden Bereiche.
final class ImportReady extends WorkspaceImportState {
  const ImportReady({required this.staged, required this.selection});

  final StagedTransferImport staged;
  final Set<TransferCategory> selection;

  bool get canApply => selection.isNotEmpty;
}

final class ImportApplying extends WorkspaceImportState {
  const ImportApplying({required this.staged, required this.selection});

  final StagedTransferImport staged;
  final Set<TransferCategory> selection;
}

final class ImportSucceeded extends WorkspaceImportState {
  const ImportSucceeded(this.imported);

  final TransferCounts imported;
}

final class ImportFailed extends WorkspaceImportState {
  const ImportFailed(this.message);

  final String message;
}
