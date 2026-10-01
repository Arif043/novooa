import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/staged_transfer_import.dart';
import '../../domain/entities/transfer_category.dart';
import '../../domain/usecases/apply_workspace_import.dart';
import '../../domain/usecases/discard_workspace_import.dart';
import '../../domain/usecases/stage_workspace_import.dart';
import 'workspace_import_state.dart';

class WorkspaceImportCubit extends Cubit<WorkspaceImportState> {
  WorkspaceImportCubit(
    this._stageImport,
    this._applyImport,
    this._discardImport,
  ) : super(const ImportIdle());

  final StageWorkspaceImport _stageImport;
  final ApplyWorkspaceImport _applyImport;
  final DiscardWorkspaceImport _discardImport;

  Future<void> pickFile() async {
    if (state is ImportUploading || state is ImportApplying) return;
    emit(const ImportUploading());
    final stagedOrFailure = await _stageImport();
    if (isClosed) return;
    emit(switch (stagedOrFailure) {
      Success(success: final staged) => ImportReady(
        staged: staged,
        selection: staged.contents.categories.toSet(),
      ),
      Error(error: final failure) when failure.isCancelled =>
        const ImportIdle(),
      Error(error: final failure) => ImportFailed(failure.message),
    });
  }

  void toggle(TransferCategory category, {required bool selected}) {
    final current = state;
    if (current is! ImportReady) return;
    final selection = {...current.selection};
    selected ? selection.add(category) : selection.remove(category);
    emit(ImportReady(staged: current.staged, selection: selection));
  }

  Future<void> apply() async {
    final current = state;
    if (current is! ImportReady || !current.canApply) return;
    emit(ImportApplying(staged: current.staged, selection: current.selection));
    final importedOrFailure = await _applyImport(
      current.staged.id,
      current.selection,
    );
    if (isClosed) return;
    emit(switch (importedOrFailure) {
      Success(success: final imported) => ImportSucceeded(imported),
      Error(error: final failure) => ImportFailed(failure.message),
    });
  }

  Future<void> discard() async {
    final staged = _stagedImport();
    emit(const ImportIdle());
    if (staged != null) await _discardImport(staged.id);
  }

  void reset() => emit(const ImportIdle());

  @override
  Future<void> close() async {
    final staged = _stagedImport();
    if (staged != null) await _discardImport(staged.id);
    return super.close();
  }

  StagedTransferImport? _stagedImport() => switch (state) {
    ImportReady(:final staged) => staged,
    _ => null,
  };
}
