import 'package:get_it/get_it.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../features/data/domain/entities/data_collection.dart';
import '../../features/data/domain/repositories/data_collection_repository.dart';
import '../../features/data/domain/repositories/data_file_gateway.dart';
import '../../features/data/domain/repositories/data_repository.dart';
import '../../features/data/domain/repositories/data_transfer_repository.dart';
import '../../features/data/domain/usecases/data_collections.dart';
import '../../features/data/domain/usecases/data_records.dart';
import '../../features/data/domain/usecases/data_transfer.dart';
import '../../features/data/infrastructure/datasources/file_picker_data_file_gateway.dart';
import '../../features/data/infrastructure/repositories/local_data_collection_repository.dart';
import '../../features/data/infrastructure/repositories/local_data_repository.dart';
import '../../features/data/infrastructure/repositories/local_data_transfer_repository.dart';
import '../../features/data/presentation/cubits/database_actions_cubit.dart';
import '../../features/data/presentation/cubits/database_cubit.dart';
import '../../features/data/presentation/cubits/database_import_cubit.dart';

/// Datenbank-Seite: Datensätze, Sammlungsverwaltung und Import/Export über die Runtime.
void configureStandaloneDataDependencies(GetIt locator) {
  _registerRepositories(locator);
  _registerUseCases(locator);
  _registerCubits(locator);
}

void _registerRepositories(GetIt locator) => locator
  ..registerLazySingleton<DataRepository>(
    () => LocalDataRepository(locator<WorkspaceApiClient>()),
  )
  ..registerLazySingleton<DataCollectionRepository>(
    () => LocalDataCollectionRepository(locator<WorkspaceApiClient>()),
  )
  ..registerLazySingleton<DataTransferRepository>(
    () => LocalDataTransferRepository(locator<WorkspaceBinaryClient>()),
  )
  ..registerLazySingleton<DataFileGateway>(FilePickerDataFileGateway.new);

void _registerUseCases(GetIt locator) {
  DataRepository records() => locator<DataRepository>();
  DataCollectionRepository collections() => locator<DataCollectionRepository>();
  DataTransferRepository transfer() => locator<DataTransferRepository>();
  locator
    ..registerLazySingleton(() => ListDataCollections(records()))
    ..registerLazySingleton(() => QueryDataRecords(records()))
    ..registerLazySingleton(() => CreateDataRecord(records()))
    ..registerLazySingleton(() => UpdateDataRecord(records()))
    ..registerLazySingleton(() => DeleteDataRecord(records()))
    ..registerLazySingleton(() => CreateDataCollection(collections()))
    ..registerLazySingleton(() => RenameDataCollection(collections()))
    ..registerLazySingleton(() => DeleteDataCollection(collections()))
    ..registerLazySingleton(() => ClearDataCollection(collections()))
    ..registerLazySingleton(() => DeleteDataRecords(collections()))
    ..registerLazySingleton(
      () => ExportDataRecords(transfer(), locator<DataFileGateway>()),
    )
    ..registerLazySingleton(
      () => PickDataImportFile(locator<DataFileGateway>()),
    )
    ..registerLazySingleton(() => PreviewDataImport(transfer()))
    ..registerLazySingleton(() => ImportDataRecords(transfer()));
}

void _registerCubits(GetIt locator) => locator
  ..registerFactory(
    () => DatabaseCubit(
      listCollections: locator(),
      queryRecords: locator(),
      createRecord: locator(),
      updateRecord: locator(),
      deleteRecord: locator(),
    ),
  )
  ..registerFactory(
    () => DatabaseActionsCubit(
      create: locator(),
      rename: locator(),
      delete: locator(),
      clear: locator(),
      deleteRecords: locator(),
      exportRecords: locator(),
    ),
  )
  ..registerFactoryParam<DatabaseImportCubit, DataCollection, void>(
    (collection, _) => DatabaseImportCubit(
      collection: collection,
      pickFile: locator(),
      preview: locator(),
      importRecords: locator(),
    ),
  );
