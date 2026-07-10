import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/file_failure.dart';
import 'package:syscat2/features/files/domain/entities/team_file.dart';
import 'package:syscat2/features/files/domain/entities/team_folder.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/domain/entities/upload_file_input.dart';
import 'package:syscat2/features/files/domain/repositories/team_file_repository.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_files.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_state.dart';

void main() {
  test('load stellt echte Team-Dateien als NodeAttachments bereit', () async {
    final repository = _FakeTeamFileRepository();
    final cubit = NodeFileAttachmentsCubit(
      _FakeAuthRepository(),
      WatchTeamFiles(repository),
    );

    cubit.load();
    repository.emit([_teamFile]);
    await Future<void>.delayed(Duration.zero);

    expect(repository.watchedTeamId, const TeamId('personal_user.1'));
    expect(cubit.state.status, NodeFileAttachmentsStatus.ready);
    expect(cubit.state.files.single.id, 'file.1:version.7');
    expect(cubit.state.files.single.storagePath, _teamFile.storagePath);

    await cubit.close();
    await repository.close();
  });
}

final _teamFile = TeamFile(
  id: 'file.1',
  teamId: const TeamId('personal_user.1'),
  ownerUid: 'user.1',
  displayName: 'briefing.md',
  storagePath: 'teams/personal_user.1/files/file.1/versions/version.7/file.md',
  currentVersionId: 'version.7',
  contentType: 'text/markdown',
  sizeBytes: 12000,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _FakeTeamFileRepository implements TeamFileRepository {
  final StreamController<List<TeamFile>> _controller =
      StreamController.broadcast();

  TeamId? watchedTeamId;

  @override
  Stream<List<TeamFile>> watchFiles(TeamId teamId) {
    watchedTeamId = teamId;
    return _controller.stream;
  }

  @override
  Stream<List<TeamFolder>> watchFolders(TeamId teamId) {
    return const Stream.empty();
  }

  void emit(List<TeamFile> files) {
    _controller.add(files);
  }

  Future<void> close() => _controller.close();

  @override
  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
    required String? folderId,
  }) async {
    return const Result.error(FileFailure(FileFailureKind.uploadFailed));
  }

  @override
  Future<Result<TeamFolder, FileFailure>> createFolder({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  }) async {
    return const Result.error(FileFailure(FileFailureKind.createFolderFailed));
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  AuthUser? currentUser() {
    return const AuthUser(
      id: UniqueId('user.1'),
      email: 'ada@example.com',
      displayName: 'Ada',
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    return const Result.error(AuthFailure(AuthFailureKind.unknown));
  }

  @override
  Future<Result<Unit, AuthFailure>> signOut() async {
    return const Result.success(unit);
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    return const Result.error(AuthFailure(AuthFailureKind.unknown));
  }
}
