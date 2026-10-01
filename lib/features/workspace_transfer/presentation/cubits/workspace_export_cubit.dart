import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/transfer_category.dart';
import '../../domain/usecases/export_workspace_to_file.dart';
import 'workspace_export_state.dart';

class WorkspaceExportCubit extends Cubit<WorkspaceExportState> {
  WorkspaceExportCubit(this._exportWorkspace)
    : super(WorkspaceExportState.initial());

  final ExportWorkspaceToFile _exportWorkspace;

  void toggle(TransferCategory category, {required bool selected}) {
    final selection = {...state.selection};
    selected ? selection.add(category) : selection.remove(category);
    emit(state.copyWith(selection: selection, status: const ExportIdle()));
  }

  Future<void> export() async {
    if (!state.canExport) return;
    emit(state.copyWith(status: const ExportRunning()));
    final savedOrFailure = await _exportWorkspace(state.selection);
    if (isClosed) return;
    final status = switch (savedOrFailure) {
      Success() => const ExportSaved(),
      Error(error: final failure) when failure.isCancelled =>
        const ExportIdle(),
      Error(error: final failure) => ExportFailed(failure.message),
    };
    emit(state.copyWith(status: status));
  }
}
