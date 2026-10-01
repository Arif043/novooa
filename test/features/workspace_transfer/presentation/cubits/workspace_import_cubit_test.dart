import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_category.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_failure.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/apply_workspace_import.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/discard_workspace_import.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/stage_workspace_import.dart';
import 'package:syscat2/features/workspace_transfer/presentation/cubits/workspace_import_cubit.dart';
import 'package:syscat2/features/workspace_transfer/presentation/cubits/workspace_import_state.dart';

import '../../transfer_fakes.dart';

void main() {
  late FakeTransferRepository repository;
  late FakeTransferFileGateway files;
  late WorkspaceImportCubit cubit;

  setUp(() {
    repository = FakeTransferRepository();
    files = FakeTransferFileGateway();
    cubit = WorkspaceImportCubit(
      StageWorkspaceImport(repository, files),
      ApplyWorkspaceImport(repository),
      DiscardWorkspaceImport(repository),
    );
  });

  test(
    'stages a picked file and preselects all contained categories',
    () async {
      await cubit.pickFile();

      final state = cubit.state as ImportReady;
      expect(state.selection, {TransferCategory.files, TransferCategory.tasks});
      expect(state.staged, sampleStagedImport);
      await cubit.close();
    },
  );

  test('stays idle when the file dialog is cancelled', () async {
    files.pickResult = const Error(TransferFailure.cancelled());

    await cubit.pickFile();

    expect(cubit.state, isA<ImportIdle>());
    await cubit.close();
  });

  test('applies only the categories that remain selected', () async {
    await cubit.pickFile();
    cubit.toggle(TransferCategory.files, selected: false);

    await cubit.apply();

    expect(repository.appliedCategories, {TransferCategory.tasks});
    final state = cubit.state as ImportSucceeded;
    expect(state.imported.countOf(TransferCategory.tasks), 2);
    await cubit.close();
  });

  test('shows the runtime message when the import fails', () async {
    repository.applyResult = const Error(runtimeFailure);
    await cubit.pickFile();

    await cubit.apply();

    expect((cubit.state as ImportFailed).message, runtimeFailure.message);
    await cubit.close();
  });

  test('shows the validation message for an invalid file', () async {
    repository.stageResult = const Error(
      TransferFailure(
        TransferFailureKind.failed,
        'Die Datei ist kein novooa-Export.',
      ),
    );

    await cubit.pickFile();

    expect(
      (cubit.state as ImportFailed).message,
      'Die Datei ist kein novooa-Export.',
    );
    await cubit.close();
  });

  test('discards a staged import on request and when closed', () async {
    await cubit.pickFile();
    await cubit.discard();
    expect(cubit.state, isA<ImportIdle>());

    await cubit.pickFile();
    await cubit.close();

    expect(repository.discarded, [
      sampleStagedImport.id,
      sampleStagedImport.id,
    ]);
  });
}
