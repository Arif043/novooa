import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_defaults.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_defaults_repository.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_repository.dart';
import 'package:syscat2/features/language_models/domain/usecases/save_language_model_defaults.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_model_defaults.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_state.dart';
import 'package:syscat2/features/teams/domain/entities/team_member.dart';
import 'package:syscat2/features/teams/domain/entities/team_workspace.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  test('lädt Modelle und gespeicherte Vorgaben zusammen', () async {
    final defaultsRepo = _Defaults(
      const LanguageModelDefaults(
        blockModelId: 'model-1',
        assistantModelId: null,
      ),
    );
    final cubit = _cubit(
      models: [_model('model-1'), _model('model-2')],
      defaultsRepo: defaultsRepo,
    );

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, LanguageModelDefaultsStatus.ready);
    expect(cubit.state.models.map((m) => m.id), ['model-1', 'model-2']);
    expect(cubit.state.defaults.blockModelId, 'model-1');
    await cubit.close();
  });

  test(
    'saveBlockDefault behält die bestehende Assistenten-Vorgabe bei',
    () async {
      final defaultsRepo = _Defaults(
        const LanguageModelDefaults(
          blockModelId: null,
          assistantModelId: 'model-2',
        ),
      );
      final cubit = _cubit(
        models: [_model('model-1'), _model('model-2')],
        defaultsRepo: defaultsRepo,
      );
      await cubit.load();
      await pumpEventQueue();

      await cubit.saveBlockDefault('model-1');

      expect(defaultsRepo.saved?.blockModelId, 'model-1');
      expect(defaultsRepo.saved?.assistantModelId, 'model-2');
      await cubit.close();
    },
  );

  test(
    'saveAssistantDefault behält die bestehende Baustein-Vorgabe bei',
    () async {
      final defaultsRepo = _Defaults(
        const LanguageModelDefaults(
          blockModelId: 'model-1',
          assistantModelId: null,
        ),
      );
      final cubit = _cubit(
        models: [_model('model-1'), _model('model-2')],
        defaultsRepo: defaultsRepo,
      );
      await cubit.load();
      await pumpEventQueue();

      await cubit.saveAssistantDefault('model-2');

      expect(defaultsRepo.saved?.blockModelId, 'model-1');
      expect(defaultsRepo.saved?.assistantModelId, 'model-2');
      await cubit.close();
    },
  );

  test('meldet einen Fehler, wenn niemand angemeldet ist', () async {
    final cubit = LanguageModelDefaultsCubit(
      _Auth(signedIn: false),
      WatchLanguageModels(_Models(const [])),
      WatchLanguageModelDefaults(
        _Defaults(const LanguageModelDefaults.empty()),
      ),
      SaveLanguageModelDefaults(_Defaults(const LanguageModelDefaults.empty())),
      GetCurrentTeamId(_Teams()),
    );

    await cubit.load();

    expect(cubit.state.status, LanguageModelDefaultsStatus.failure);
    await cubit.close();
  });
}

LanguageModel _model(String id) => LanguageModel(
  id: id,
  name: id,
  modelId: id,
  supportsImageInput: false,
  supportsStructuredOutput: false,
  supportsImageGeneration: false,
);

LanguageModelDefaultsCubit _cubit({
  required List<LanguageModel> models,
  required _Defaults defaultsRepo,
}) {
  return LanguageModelDefaultsCubit(
    _Auth(),
    WatchLanguageModels(_Models(models)),
    WatchLanguageModelDefaults(defaultsRepo),
    SaveLanguageModelDefaults(defaultsRepo),
    GetCurrentTeamId(_Teams()),
  );
}

class _Models implements LanguageModelRepository {
  _Models(this.models);
  final List<LanguageModel> models;
  @override
  Future<void> saveLanguageModel(dynamic draft) async {}
  @override
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId) =>
      Stream.value(models);
}

class _Defaults implements LanguageModelDefaultsRepository {
  _Defaults(this._current);
  LanguageModelDefaults _current;
  LanguageModelDefaults? saved;

  @override
  Stream<LanguageModelDefaults> watchLanguageModelDefaults(TeamId teamId) =>
      Stream.value(_current);

  @override
  Future<void> saveLanguageModelDefaults(
    TeamId teamId,
    LanguageModelDefaults defaults,
  ) async {
    saved = defaults;
    _current = defaults;
  }
}

class _Auth implements AuthRepository {
  _Auth({this.signedIn = true});
  final bool signedIn;
  @override
  AuthUser? currentUser() => signedIn
      ? const AuthUser(
          id: UniqueId('user'),
          email: 'user@example.com',
          displayName: 'Nutzer',
        )
      : null;
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
