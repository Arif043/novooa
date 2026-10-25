import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/skill_catalog.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/repositories/skill_catalog_repository.dart';
import 'skill_json_mapper.dart';

class LocalSkillCatalogRepository implements SkillCatalogRepository {
  const LocalSkillCatalogRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<bool> isAvailable() async {
    try {
      final json = await _client.get('/v1/skills/catalog/status');
      return json['available'] == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<Result<List<CatalogSkill>, SkillFailure>> search(String query) =>
      _attempt(
        () async => catalogSkillsFromJson(
          await _client.get(
            '/v1/skills/catalog/search?q=${Uri.encodeQueryComponent(query)}',
          ),
        ),
      );

  @override
  Future<Result<CatalogPage, SkillFailure>> browse(
    CatalogView view,
    int page,
  ) => _attempt(
    () async => catalogPageFromJson(
      await _client.get(
        '/v1/skills/catalog/browse?view=${_viewName(view)}&page=$page',
      ),
    ),
  );

  @override
  Future<Result<List<CatalogAudit>, SkillFailure>> audits(String skillId) =>
      _attempt(
        () async => auditsFromJson(
          await _client.get(
            '/v1/skills/catalog/audits?id=${Uri.encodeQueryComponent(skillId)}',
          ),
        ),
      );

  String _viewName(CatalogView view) => switch (view) {
    CatalogView.allTime => 'all-time',
    CatalogView.trending => 'trending',
    CatalogView.hot => 'hot',
  };

  Future<Result<T, SkillFailure>> _attempt<T extends Object>(
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } on WorkspaceHttpException catch (error) {
      return Error(SkillFailure(error.message));
    } on Object {
      return const Error(SkillFailure('Der Katalog ist nicht erreichbar.'));
    }
  }
}
