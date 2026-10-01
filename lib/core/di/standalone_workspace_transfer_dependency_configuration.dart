import 'package:get_it/get_it.dart';

import '../../features/workspace_transfer/domain/repositories/transfer_file_gateway.dart';
import '../../features/workspace_transfer/domain/repositories/workspace_transfer_repository.dart';
import '../../features/workspace_transfer/domain/usecases/apply_workspace_import.dart';
import '../../features/workspace_transfer/domain/usecases/discard_workspace_import.dart';
import '../../features/workspace_transfer/domain/usecases/export_workspace_to_file.dart';
import '../../features/workspace_transfer/domain/usecases/stage_workspace_import.dart';
import '../../features/workspace_transfer/infrastructure/datasources/file_picker_transfer_file_gateway.dart';
import '../../features/workspace_transfer/infrastructure/repositories/local_workspace_transfer_repository.dart';
import '../../features/workspace_transfer/presentation/cubits/workspace_export_cubit.dart';
import '../../features/workspace_transfer/presentation/cubits/workspace_import_cubit.dart';
import '../network/workspace_api_client.dart';
import '../network/workspace_binary_client.dart';

/// Import/Export gibt es nur in der lokalen Runtime.
void configureStandaloneWorkspaceTransferDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<WorkspaceTransferRepository>(
      () => LocalWorkspaceTransferRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceBinaryClient>(),
      ),
    )
    ..registerLazySingleton<TransferFileGateway>(
      FilePickerTransferFileGateway.new,
    )
    ..registerLazySingleton(
      () => ExportWorkspaceToFile(
        locator<WorkspaceTransferRepository>(),
        locator<TransferFileGateway>(),
      ),
    )
    ..registerLazySingleton(
      () => StageWorkspaceImport(
        locator<WorkspaceTransferRepository>(),
        locator<TransferFileGateway>(),
      ),
    )
    ..registerLazySingleton(
      () => ApplyWorkspaceImport(locator<WorkspaceTransferRepository>()),
    )
    ..registerLazySingleton(
      () => DiscardWorkspaceImport(locator<WorkspaceTransferRepository>()),
    )
    ..registerFactory(
      () => WorkspaceExportCubit(locator<ExportWorkspaceToFile>()),
    )
    ..registerFactory(
      () => WorkspaceImportCubit(
        locator<StageWorkspaceImport>(),
        locator<ApplyWorkspaceImport>(),
        locator<DiscardWorkspaceImport>(),
      ),
    );
}
