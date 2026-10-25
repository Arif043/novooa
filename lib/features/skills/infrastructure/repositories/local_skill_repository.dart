import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/repositories/skill_repository.dart';
import 'skill_json_mapper.dart';

/// Skills-Ordner der lokalen Runtime über deren HTTP-API.
class LocalSkillRepository implements SkillRepository {
  const LocalSkillRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<Skill>> watchSkills(TeamId teamId) {
    return watchWorkspaceChannel('skills', _load, _channel);
  }

  Future<List<Skill>> _load() async =>
      skillsFromJson(await _client.get('/v1/skills'));

  @override
  Future<Result<Unit, SkillFailure>> deleteSkill(String name) async {
    try {
      await _client.delete('/v1/skills/${Uri.encodeComponent(name)}');
      return const Success(unit);
    } on WorkspaceHttpException catch (error) {
      return Error(SkillFailure(error.message));
    } on Object {
      return const Error(SkillFailure.deleteFailed);
    }
  }
}
