import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/file_failure.dart';
import 'package:syscat2/features/files/domain/entities/file_version.dart';
import 'package:syscat2/features/files/domain/entities/team_file.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/domain/entities/upload_file_input.dart';
import 'package:syscat2/features/files/domain/repositories/file_version_repository.dart';
import 'package:syscat2/features/files/domain/usecases/create_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/download_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/watch_file_versions.dart';
import 'package:syscat2/features/files/presentation/cubits/file_detail_cubit.dart';

void main() {
  test('save erstellt eine neue Version mit dem Editorinhalt', () async {
    final repository = _FileVersionRepository();
    final cubit = FileDetailCubit(
      _AuthRepository(),
      WatchFileVersions(repository),
      DownloadFileVersion(repository),
      CreateFileVersion(repository),
    );

    cubit.load(_file);
    await cubit.save('Aktualisierter Inhalt');

    expect(
      repository.savedInput?.bytes,
      Uint8List.fromList('Aktualisierter Inhalt'.codeUnits),
    );
    expect(repository.savedFile?.id, _file.id);
    await cubit.close();
  });
}

final _file = TeamFile(
  id: 'file.1',
  teamId: TeamId('team.1'),
  ownerUid: 'user.1',
  displayName: 'notiz.txt',
  storagePath: 'path',
  currentVersionId: 'version.1',
  contentType: 'text/plain',
  sizeBytes: 5,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  currentVersionCreatedAt: DateTime(2026),
);

class _FileVersionRepository implements FileVersionRepository {
  UploadFileInput? savedInput;
  TeamFile? savedFile;

  @override
  Future<Result<TeamFile, FileFailure>> createVersion({
    required TeamFile file,
    required String ownerUid,
    required UploadFileInput input,
  }) async {
    savedFile = file;
    savedInput = input;
    return Success(file);
  }

  @override
  Future<Result<Uint8List, FileFailure>> downloadVersion(
    FileVersion version,
  ) async => Success(Uint8List(0));

  @override
  Stream<List<FileVersion>> watchVersions(TeamId teamId, String fileId) =>
      const Stream.empty();
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
