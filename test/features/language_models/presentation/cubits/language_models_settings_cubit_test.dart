import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection_draft.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_connection_repository.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_repository.dart';
import 'package:syscat2/features/language_models/domain/usecases/connect_language_models.dart';
import 'package:syscat2/features/language_models/domain/usecases/save_language_model.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import 'package:syscat2/features/teams/domain/entities/team_member.dart';
import 'package:syscat2/features/teams/domain/entities/team_workspace.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  test('verbindet einen lokalen Anbieter ohne Modellwahl', () async {
    final connections = _Connections();
    final cubit = LanguageModelsSettingsCubit(
      _Auth(),
      WatchLanguageModels(_Models()),
      SaveLanguageModel(_Models()),
      GetCurrentTeamId(_Teams()),
      allowsKeylessLocalEndpoint: true,
      connectLanguageModels: ConnectLanguageModels(connections),
    );

    cubit.updateProvider(LanguageModelProvider.googleAi);
    cubit.updateApiKey('provider-api-key');
    await cubit.connect();

    expect(connections.draft?.provider, LanguageModelProvider.googleAi);
    expect(connections.draft?.apiKey, 'provider-api-key');
    expect(cubit.state.message, 'Modelle wurden verbunden.');
    await cubit.close();
  });

  test(
    'bereitet Ollama ohne API-Key am lokalen Standardendpunkt vor',
    () async {
      final connections = _Connections();
      final cubit = _cubit(connections);

      cubit.updateProvider(LanguageModelProvider.ollama);
      await cubit.connect();

      expect(connections.draft?.provider, LanguageModelProvider.ollama);
      expect(
        connections.draft?.baseUrl,
        'http://host.docker.internal:11434/v1',
      );
      expect(connections.draft?.apiKey, isEmpty);
      await cubit.close();
    },
  );
}

LanguageModelsSettingsCubit _cubit(_Connections connections) {
  return LanguageModelsSettingsCubit(
    _Auth(),
    WatchLanguageModels(_Models()),
    SaveLanguageModel(_Models()),
    GetCurrentTeamId(_Teams()),
    allowsKeylessLocalEndpoint: true,
    connectLanguageModels: ConnectLanguageModels(connections),
  );
}

class _Connections implements LanguageModelConnectionRepository {
  LanguageModelConnectionDraft? draft;
  @override
  Future<void> connectLanguageModels(
    LanguageModelConnectionDraft value,
  ) async => draft = value;
}

class _Models implements LanguageModelRepository {
  @override
  Future<void> saveLanguageModel(LanguageModelDraft draft) async {}
  @override
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId) =>
      const Stream.empty();
}

class _Auth implements AuthRepository {
  @override
  AuthUser? currentUser() => const AuthUser(
    id: UniqueId('user'),
    email: 'user@example.com',
    displayName: 'Nutzer',
  );
  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();
  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<Result<Unit, AuthFailure>> signOut() => throw UnimplementedError();
  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) => throw UnimplementedError();
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team');
  @override
  Future<void> addCurrentTeamMember(String identifier) async {}
  @override
  Future<void> removeCurrentTeamMember(String uid) async {}
  @override
  Future<void> updateCurrentTeamName(String name) async {}
  @override
  Stream<TeamId> watchCurrentTeamId() => const Stream.empty();
  @override
  Stream<TeamWorkspace> watchCurrentTeam() => const Stream.empty();
  @override
  Stream<List<TeamMember>> watchCurrentTeamMembers() => const Stream.empty();
}
