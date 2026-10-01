import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/staged_transfer_import.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_archive.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_category.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_counts.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_failure.dart';
import 'package:syscat2/features/workspace_transfer/domain/repositories/transfer_file_gateway.dart';
import 'package:syscat2/features/workspace_transfer/domain/repositories/workspace_transfer_repository.dart';

final sampleArchive = TransferArchive(
  fileName: 'novooa-export-2026-10-01.zip',
  bytes: Uint8List.fromList([80, 75]),
);

final sampleStagedImport = StagedTransferImport(
  id: TransferImportId('import-1'),
  exportedAt: DateTime(2026, 10, 1, 8, 30),
  contents: TransferCounts({
    TransferCategory.files: 3,
    TransferCategory.tasks: 2,
  }),
);

const runtimeFailure = TransferFailure(
  TransferFailureKind.failed,
  'Die Runtime ist nicht erreichbar.',
);

class FakeTransferRepository implements WorkspaceTransferRepository {
  Result<TransferArchive, TransferFailure> exportResult = Success(
    sampleArchive,
  );
  Result<StagedTransferImport, TransferFailure> stageResult = Success(
    sampleStagedImport,
  );
  Result<TransferCounts, TransferFailure> applyResult = Success(
    TransferCounts({TransferCategory.tasks: 2}),
  );

  Set<TransferCategory>? exportedCategories;
  Set<TransferCategory>? appliedCategories;
  final List<TransferImportId> discarded = [];

  @override
  Future<Result<TransferArchive, TransferFailure>> exportArchive(
    Set<TransferCategory> categories,
  ) async {
    exportedCategories = categories;
    return exportResult;
  }

  @override
  Future<Result<StagedTransferImport, TransferFailure>> stageImport(
    TransferArchive archive,
  ) async => stageResult;

  @override
  Future<Result<TransferCounts, TransferFailure>> applyImport(
    TransferImportId id,
    Set<TransferCategory> categories,
  ) async {
    appliedCategories = categories;
    return applyResult;
  }

  @override
  Future<void> discardImport(TransferImportId id) async => discarded.add(id);
}

class FakeTransferFileGateway implements TransferFileGateway {
  Result<Unit, TransferFailure> saveResult = Success.unit();
  Result<TransferArchive, TransferFailure> pickResult = Success(sampleArchive);
  TransferArchive? saved;

  @override
  Future<Result<Unit, TransferFailure>> save(TransferArchive archive) async {
    saved = archive;
    return saveResult;
  }

  @override
  Future<Result<TransferArchive, TransferFailure>> pick() async => pickResult;
}
