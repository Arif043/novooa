import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/repositories/file_settings_repository.dart';
import 'package:syscat2/features/files/domain/usecases/download_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/watch_file_version_limit.dart';
import 'package:syscat2/features/files/domain/usecases/watch_file_versions.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_folders.dart';
import 'package:syscat2/features/files/presentation/cubits/file_detail_cubit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_detail_state.dart';

import '../../support/fake_file_repositories.dart';

void main() {
  late FakeFileRepositories repositories;
  late FileDetailCubit cubit;

  setUp(() {
    repositories = FakeFileRepositories();
    cubit = FileDetailCubit(
      WatchTeamFile(repositories),
      WatchFileVersions(repositories),
      WatchTeamFolders(repositories),
      WatchFileVersionLimit(_Settings()),
      DownloadFileVersion(repositories),
    );
  });

  tearDown(() => cubit.close());

  FileDetailReady ready() => cubit.state as FileDetailReady;

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('zeigt zuerst die aktuelle Version und lädt ihren Inhalt', () async {
    cubit.load(testFile(versionId: 'version.2'));
    repositories.versions.add([
      testVersion('version.2'),
      testVersion('version.1'),
    ]);
    await pump();

    expect(ready().selectedVersionId, 'version.2');
    expect(ready().content, isA<FileContentLoaded>());
    expect(ready().isViewingOldVersion, isFalse);
  });

  test('wer den aktuellen Stand ansieht, folgt einer neuen Version', () async {
    cubit.load(testFile(versionId: 'version.2'));
    repositories.versions.add([
      testVersion('version.2'),
      testVersion('version.1'),
    ]);
    await pump();

    // Erst kommt der Verlauf, dann die Datei mit dem neuen Stand.
    repositories.versions.add([
      testVersion('version.3'),
      testVersion('version.2'),
      testVersion('version.1'),
    ]);
    await pump();
    repositories.files.add([testFile(versionId: 'version.3')]);
    await pump();

    expect(ready().selectedVersionId, 'version.3');
    expect(ready().isViewingOldVersion, isFalse);
  });

  test('eine bewusst gewählte alte Version bleibt stehen', () async {
    cubit.load(testFile(versionId: 'version.2'));
    repositories.versions.add([
      testVersion('version.2'),
      testVersion('version.1'),
    ]);
    await pump();
    await cubit.selectVersion(testVersion('version.1'));

    repositories.files.add([testFile(versionId: 'version.2', name: 'Neu.txt')]);
    await pump();

    expect(ready().selectedVersionId, 'version.1');
    expect(ready().isViewingOldVersion, isTrue);
    expect(ready().file.displayName, 'Neu.txt');
  });

  test('die Größenänderung bezieht sich auf die Vorversion', () async {
    cubit.load(testFile(versionId: 'version.2'));
    repositories.versions.add([
      testVersion('version.2', sizeBytes: 3000),
      testVersion('version.1', sizeBytes: 2000),
    ]);
    await pump();

    final [newer, older] = ready().versions;
    expect(ready().sizeDeltaOf(newer), 1000);
    expect(ready().sizeDeltaOf(older), isNull);
  });

  test('verschwindet die Datei, meldet der Zustand das', () async {
    cubit.load(testFile());
    repositories.files.add([]);
    await pump();

    expect(cubit.state, isA<FileDetailDeleted>());
  });
}

class _Settings implements FileSettingsRepository {
  @override
  Stream<int> watchVersionLimit() => Stream.value(10);

  @override
  Future<void> saveVersionLimit(int limit) async {}
}
