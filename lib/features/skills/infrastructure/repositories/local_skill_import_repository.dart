import 'dart:convert';

import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/entities/skill_import.dart';
import '../../domain/repositories/skill_import_repository.dart';
import 'skill_json_mapper.dart';

class LocalSkillImportRepository implements SkillImportRepository {
  const LocalSkillImportRepository(this._client, this._binaryClient);

  final WorkspaceApiClient _client;
  final WorkspaceBinaryClient _binaryClient;

  @override
  Future<Result<SkillImportPreview, SkillFailure>> preview(
    SkillImportSource source,
  ) => _attempt(() async {
    final json = switch (source) {
      GitHubImportSource(:final url) => await _client.post(
        '/v1/skills/imports',
        {
          'github': {'url': url},
        },
      ),
      CatalogImportSource(:final id) => await _client.post(
        '/v1/skills/imports',
        {
          'skillsSh': {'id': id},
        },
      ),
      FolderImportSource() => await _client.post(
        '/v1/skills/imports',
        _folderBody(source),
      ),
      ArchiveImportSource() => await _binaryClient.postBytes(
        '/v1/skills/imports/archive?name=${Uri.encodeQueryComponent(source.fileName)}',
        body: source.bytes,
        contentType: 'application/zip',
      ),
    };
    return previewFromJson(json);
  });

  @override
  Future<Result<List<Skill>, SkillFailure>> commit(
    String importId,
    List<String> names,
  ) => _attempt(() async {
    final json = await _client.post(
      '/v1/skills/imports/${Uri.encodeComponent(importId)}/commit',
      {'names': names},
    );
    return skillsFromJson(json);
  });

  Map<String, Object?> _folderBody(FolderImportSource source) => {
    'folder': {
      'name': source.name,
      'files': [
        for (final file in source.files)
          {'path': file.path, 'contentBase64': base64Encode(file.bytes)},
      ],
    },
  };

  Future<Result<T, SkillFailure>> _attempt<T extends Object>(
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } on WorkspaceHttpException catch (error) {
      return Error(SkillFailure(error.message));
    } on Object {
      return const Error(SkillFailure.importFailed);
    }
  }
}
