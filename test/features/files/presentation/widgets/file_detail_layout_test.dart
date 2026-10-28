import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/repositories/file_settings_repository.dart';
import 'package:syscat2/features/files/domain/usecases/copy_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/create_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/delete_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/move_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/rename_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/restore_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/save_file_version_to_device.dart';
import 'package:syscat2/features/files/domain/usecases/download_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/watch_file_version_limit.dart';
import 'package:syscat2/features/files/domain/usecases/watch_file_versions.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_folders.dart';
import 'package:syscat2/features/files/presentation/cubits/file_actions_cubit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_actions_dependencies.dart';
import 'package:syscat2/features/files/presentation/cubits/file_detail_cubit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_detail_state.dart';
import 'package:syscat2/features/files/presentation/widgets/detail/file_detail_layout.dart';

import '../../support/fake_file_repositories.dart';

final _state = FileDetailReady(
  file: testFile(versionId: 'version.2'),
  versions: [
    testVersion('version.2', sizeBytes: 3072),
    testVersion('version.1', day: 20),
  ],
  versionLimit: 10,
  selectedVersionId: 'version.2',
  content: FileContentLoaded(Uint8List.fromList('Hallo Welt'.codeUnits)),
);

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repositories = FakeFileRepositories();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => FileDetailCubit(
              WatchTeamFile(repositories),
              WatchFileVersions(repositories),
              WatchTeamFolders(repositories),
              WatchFileVersionLimit(_Settings()),
              DownloadFileVersion(repositories),
            ),
          ),
          BlocProvider(create: (_) => _actions(repositories)),
        ],
        child: Scaffold(body: FileDetailLayout(state: _state)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  testWidgets('am Desktop Inhalt und Inspektor nebeneinander, Aktionen als '
      'Symbolknöpfe', (tester) async {
    await _pump(tester, const Size(1400, 900));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Umbenennen'), findsOneWidget);
    expect(find.byTooltip('Herunterladen'), findsOneWidget);
    expect(find.text('Versionen (2)'), findsOneWidget);
    expect(find.text('Aktuell'), findsOneWidget);
    expect(find.textContaining('Textdokument · 2 KB'), findsOneWidget);
  });

  testWidgets('auf dem Handy ohne Überlauf, Aktionen im Menü', (tester) async {
    await _pump(tester, const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Umbenennen'), findsNothing);
    await tester.tap(find.byTooltip('Weitere Aktionen').first);
    await tester.pumpAndSettle();
    expect(find.text('Umbenennen'), findsOneWidget);
    expect(find.text('Löschen'), findsOneWidget);
  });

  testWidgets('mit großer Schrift bleibt die Handyansicht ohne Überlauf', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, const Size(390, 844));

    expect(tester.takeException(), isNull);
  });
}

FileActionsCubit _actions(FakeFileRepositories repositories) =>
    FileActionsCubit(
      _NoUser(),
      FileActionsDependencies(
        rename: RenameTeamFile(repositories),
        move: MoveTeamFile(repositories),
        copy: CopyTeamFile(repositories),
        delete: DeleteTeamFile(repositories),
        restore: RestoreFileVersion(repositories),
        saveToDevice: SaveFileVersionToDevice(
          repositories,
          FakeFileSaveGateway(),
        ),
        createVersion: CreateFileVersion(repositories),
      ),
    );

class _NoUser implements AuthRepository {
  @override
  AuthUser? currentUser() => null;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();
}

class _Settings implements FileSettingsRepository {
  @override
  Stream<int> watchVersionLimit() => const Stream.empty();

  @override
  Future<void> saveVersionLimit(int limit) async {}
}
