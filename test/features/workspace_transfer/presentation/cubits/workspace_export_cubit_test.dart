import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_category.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_failure.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/export_workspace_to_file.dart';
import 'package:syscat2/features/workspace_transfer/presentation/cubits/workspace_export_cubit.dart';
import 'package:syscat2/features/workspace_transfer/presentation/cubits/workspace_export_state.dart';

import '../../transfer_fakes.dart';

void main() {
  late FakeTransferRepository repository;
  late FakeTransferFileGateway files;
  late WorkspaceExportCubit cubit;

  setUp(() {
    repository = FakeTransferRepository();
    files = FakeTransferFileGateway();
    cubit = WorkspaceExportCubit(ExportWorkspaceToFile(repository, files));
  });

  tearDown(() => cubit.close());

  test('selects all categories initially', () {
    expect(cubit.state.selection, TransferCategory.values.toSet());
    expect(cubit.state.canExport, isTrue);
  });

  test('exports the selected categories and saves the archive', () async {
    cubit.toggle(TransferCategory.files, selected: false);

    await cubit.export();

    expect(repository.exportedCategories, {
      TransferCategory.data,
      TransferCategory.knowledge,
      TransferCategory.tasks,
    });
    expect(files.saved, sampleArchive);
    expect(cubit.state.status, isA<ExportSaved>());
  });

  test('shows the runtime message when the export fails', () async {
    repository.exportResult = const Error(runtimeFailure);

    await cubit.export();

    final status = cubit.state.status;
    expect(status, isA<ExportFailed>());
    expect((status as ExportFailed).message, runtimeFailure.message);
    expect(files.saved, isNull);
  });

  test('returns to idle when saving is cancelled', () async {
    files.saveResult = const Error(TransferFailure.cancelled());

    await cubit.export();

    expect(cubit.state.status, isA<ExportIdle>());
  });

  test('cannot export without a selection', () async {
    for (final category in TransferCategory.values) {
      cubit.toggle(category, selected: false);
    }

    await cubit.export();

    expect(cubit.state.canExport, isFalse);
    expect(repository.exportedCategories, isNull);
  });
}
