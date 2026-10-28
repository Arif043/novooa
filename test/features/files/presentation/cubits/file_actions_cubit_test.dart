import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/file_failure.dart';
import 'package:syscat2/features/files/domain/entities/upload_file_input.dart';
import 'package:syscat2/features/files/domain/usecases/copy_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/create_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/delete_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/move_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/rename_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/restore_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/save_file_version_to_device.dart';
import 'package:syscat2/features/files/presentation/cubits/file_actions_cubit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_actions_dependencies.dart';
import 'package:syscat2/features/files/presentation/cubits/file_actions_state.dart';

import '../../support/fake_file_repositories.dart';

void main() {
  late FakeFileRepositories repositories;
  late FakeFileSaveGateway gateway;
  late FileActionsCubit cubit;

  setUp(() {
    repositories = FakeFileRepositories();
    gateway = FakeFileSaveGateway();
    cubit = FileActionsCubit(
      _AuthRepository(),
      FileActionsDependencies(
        rename: RenameTeamFile(repositories),
        move: MoveTeamFile(repositories),
        copy: CopyTeamFile(repositories),
        delete: DeleteTeamFile(repositories),
        restore: RestoreFileVersion(repositories),
        saveToDevice: SaveFileVersionToDevice(repositories, gateway),
        createVersion: CreateFileVersion(repositories),
      ),
    );
  });

  tearDown(() => cubit.close());

  group('Umbenennen', () {
    test('ein neuer Name wird übernommen und gemeldet', () async {
      final failure = await cubit.rename(testFile(), 'Protokoll.txt');

      expect(failure, isNull);
      expect(repositories.lastName?.value, 'Protokoll.txt');
      expect(cubit.state, isA<FileActionSucceeded>());
    });

    test('ein vergebener Name kommt zum Dialog zurück', () async {
      repositories.failWith = FileFailureKind.nameTaken;

      final failure = await cubit.rename(testFile(), 'Belegt.txt');

      expect(failure, FileFailureKind.nameTaken);
      expect((cubit.state as FileActionFailed).kind, FileFailureKind.nameTaken);
    });

    test('ein ungültiger Name erreicht die Runtime nicht', () async {
      final failure = await cubit.rename(testFile(), 'a/b.txt');

      expect(failure, FileFailureKind.invalidFileName);
      expect(repositories.calls, isEmpty);
    });

    test('der unveränderte Name ist kein Aufruf', () async {
      await cubit.rename(testFile(name: 'Bericht.txt'), 'Bericht.txt');

      expect(repositories.calls, isEmpty);
      expect(cubit.state, isA<FileActionSucceeded>());
    });
  });

  test('Verschieben schickt den Zielordner, oberste Ebene ist null', () async {
    await cubit.move(testFile(folderId: 'archiv'), null);

    expect(repositories.calls, ['move']);
    expect(repositories.lastFolderId, isNull);
  });

  test(
    'die Kopie bekommt den Zusatz vor der Endung und ist zu öffnen',
    () async {
      await cubit.copy(testFile(name: 'Bericht.txt'), ' (Kopie)');

      final state = cubit.state as FileActionSucceeded;
      expect(repositories.lastName?.value, 'Bericht (Kopie).txt');
      expect(state.createdFile?.id, 'file.copy');
    },
  );

  test('Löschen entfernt die Datei', () async {
    await cubit.delete(testFile());

    expect(repositories.calls, ['delete:file.1']);
    expect((cubit.state as FileActionSucceeded).action, FileAction.delete);
  });

  group('Herunterladen', () {
    test('speichert die Version unter dem heutigen Namen', () async {
      await cubit.download(testFile(name: 'Neu.txt'), testVersion('version.1'));

      expect(gateway.savedName, 'Neu.txt');
      expect(gateway.savedBytes, Uint8List.fromList('version.1'.codeUnits));
    });

    test('ein Abbruch ist ein stiller Fehlschlag', () async {
      gateway.cancel = true;

      final failure = await cubit.download(
        testFile(),
        testVersion('version.1'),
      );

      expect(failure, FileFailureKind.cancelled);
    });
  });

  test('Wiederherstellen nennt die gewählte Version', () async {
    await cubit.restore(testVersion('version.1'));

    expect(repositories.calls, ['restore:version.1']);
  });

  test('eine hochgeladene Datei wird neue Version derselben Datei', () async {
    final input = UploadFileInput(
      name: 'Bericht-neu.txt',
      bytes: Uint8List.fromList([1, 2]),
      sizeBytes: 2,
      contentType: 'text/plain',
    );

    await cubit.uploadVersion(testFile(), input);

    expect(repositories.createdInput, same(input));
  });

  test('Text und Bild werden mit Name und Typ der Datei gespeichert', () async {
    await cubit.saveText(testFile(), 'Hallo');
    expect(
      repositories.createdInput?.bytes,
      Uint8List.fromList('Hallo'.codeUnits),
    );

    final png = testFile(name: 'Logo.png', contentType: 'image/png');
    await cubit.saveImage(png, Uint8List.fromList([9]));
    expect(repositories.createdInput?.name, 'Logo.png');
    expect(repositories.createdInput?.contentType, 'image/png');
    expect((cubit.state as FileActionSucceeded).action, FileAction.saveImage);
  });
}

class _AuthRepository implements AuthRepository {
  @override
  AuthUser? currentUser() => const AuthUser(
    id: UniqueId('user.1'),
    email: 'test@example.com',
    displayName: 'Test',
  );

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();
}
