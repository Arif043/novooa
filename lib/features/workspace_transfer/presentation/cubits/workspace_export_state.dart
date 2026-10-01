import '../../domain/entities/transfer_category.dart';

sealed class ExportStatus {
  const ExportStatus();
}

final class ExportIdle extends ExportStatus {
  const ExportIdle();
}

final class ExportRunning extends ExportStatus {
  const ExportRunning();
}

final class ExportSaved extends ExportStatus {
  const ExportSaved();
}

final class ExportFailed extends ExportStatus {
  const ExportFailed(this.message);

  final String message;
}

class WorkspaceExportState {
  const WorkspaceExportState({required this.selection, required this.status});

  WorkspaceExportState.initial()
    : selection = TransferCategory.values.toSet(),
      status = const ExportIdle();

  final Set<TransferCategory> selection;
  final ExportStatus status;

  bool get canExport => selection.isNotEmpty && status is! ExportRunning;

  WorkspaceExportState copyWith({
    Set<TransferCategory>? selection,
    ExportStatus? status,
  }) => WorkspaceExportState(
    selection: selection ?? this.selection,
    status: status ?? this.status,
  );
}
