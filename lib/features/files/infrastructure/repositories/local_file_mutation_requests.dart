import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/file_failure.dart';
import '../../domain/entities/file_name.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import 'local_file_json_mapper.dart';

/// Umbenennen, Verschieben, Kopieren und Wiederherstellen über die Runtime.
class LocalFileMutationRequests {
  const LocalFileMutationRequests(this._client);

  final WorkspaceApiClient _client;
  static const _mapper = LocalFileJsonMapper();

  Future<Result<TeamFile, FileFailure>> rename(TeamFile file, FileName name) {
    return _send(
      () => _client.patch('/v1/files/${file.id}', {'name': name.value}),
      FileFailureKind.renameFailed,
    );
  }

  Future<Result<TeamFile, FileFailure>> move(TeamFile file, String? folderId) {
    return _send(
      () => _client.patch('/v1/files/${file.id}', {'folderId': folderId}),
      FileFailureKind.moveFailed,
    );
  }

  Future<Result<TeamFile, FileFailure>> copy(TeamFile file, FileName name) {
    return _send(
      () => _client.post('/v1/files/${file.id}/copy', {'name': name.value}),
      FileFailureKind.copyFailed,
    );
  }

  Future<Result<TeamFile, FileFailure>> restore(FileVersion version) {
    final path = '/v1/files/${version.fileId}/versions/${version.id}/restore';
    return _send(
      () => _client.post(path, const {}),
      FileFailureKind.restoreFailed,
    );
  }

  Future<Result<TeamFile, FileFailure>> _send(
    Future<Map<String, Object?>> Function() request,
    FileFailureKind failureKind,
  ) async {
    try {
      return Success(_mapper.fileFrom(await request()));
    } on WorkspaceHttpException catch (error) {
      final kind = error.statusCode == 409
          ? FileFailureKind.nameTaken
          : failureKind;
      return Error(FileFailure(kind));
    } on Object {
      return Error(FileFailure(failureKind));
    }
  }
}
