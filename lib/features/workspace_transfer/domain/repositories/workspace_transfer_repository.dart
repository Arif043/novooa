import 'package:multiple_result/multiple_result.dart';

import '../entities/staged_transfer_import.dart';
import '../entities/transfer_archive.dart';
import '../entities/transfer_category.dart';
import '../entities/transfer_counts.dart';
import '../entities/transfer_failure.dart';

abstract interface class WorkspaceTransferRepository {
  Future<Result<TransferArchive, TransferFailure>> exportArchive(
    Set<TransferCategory> categories,
  );

  Future<Result<StagedTransferImport, TransferFailure>> stageImport(
    TransferArchive archive,
  );

  Future<Result<TransferCounts, TransferFailure>> applyImport(
    TransferImportId id,
    Set<TransferCategory> categories,
  );

  Future<void> discardImport(TransferImportId id);
}
