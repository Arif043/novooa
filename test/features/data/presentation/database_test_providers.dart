import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/data/domain/usecases/data_collections.dart';
import 'package:syscat2/features/data/domain/usecases/data_transfer.dart';
import 'package:syscat2/features/data/presentation/cubits/database_actions_cubit.dart';
import 'package:syscat2/features/data/presentation/cubits/database_cubit.dart';
import 'package:syscat2/features/data/presentation/cubits/database_import_cubit.dart';

import '../support/data_test_fakes.dart';

/// Alles, was `DatabaseView` im Kontext erwartet — mit Fakes statt Runtime.
Widget databaseTestProviders({
  required DatabaseCubit cubit,
  required Widget child,
  FakeDataCollectionRepository? collections,
  FakeDataTransferRepository? transfer,
  FakeDataFileGateway? files,
}) {
  final collectionRepository = collections ?? FakeDataCollectionRepository();
  final transferRepository = transfer ?? FakeDataTransferRepository();
  final fileGateway = files ?? FakeDataFileGateway();
  return RepositoryProvider<DatabaseImportCubitFactory>.value(
    value: (collection) => DatabaseImportCubit(
      collection: collection,
      pickFile: PickDataImportFile(fileGateway),
      preview: PreviewDataImport(transferRepository),
      importRecords: ImportDataRecords(transferRepository),
    ),
    child: MultiBlocProvider(
      providers: [
        BlocProvider<DatabaseCubit>.value(value: cubit),
        BlocProvider(
          create: (_) => DatabaseActionsCubit(
            create: CreateDataCollection(collectionRepository),
            rename: RenameDataCollection(collectionRepository),
            delete: DeleteDataCollection(collectionRepository),
            clear: ClearDataCollection(collectionRepository),
            deleteRecords: DeleteDataRecords(collectionRepository),
            exportRecords: ExportDataRecords(transferRepository, fileGateway),
          ),
        ),
      ],
      child: child,
    ),
  );
}
