import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_repository.dart';
import 'package:syscat2/features/language_models/domain/usecases/save_language_model.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import 'package:syscat2/features/settings/presentation/widgets/language_model_connect_form.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/teams/domain/entities/team_member.dart';
import 'package:syscat2/features/teams/domain/entities/team_workspace.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  testWidgets(
    'blendet bereits verbundene direkte Anbieter im Dropdown aus, '
    'lässt OpenAI-kompatibel aber immer wählbar',
    (tester) async {
      final cubit = LanguageModelsSettingsCubit(
        _Auth(),
        WatchLanguageModels(_Models()),
        SaveLanguageModel(_Models()),
        GetCurrentTeamId(_Teams()),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageModelConnectForm(
              cubit: cubit,
              state: cubit.state,
              isStandalone: true,
              connections: const [
                LanguageModelConnection(
                  id: 'connection-1',
                  name: 'Google AI',
                  provider: LanguageModelProvider.googleAi,
                ),
              ],
              connectionName: TextEditingController(),
              baseUrl: TextEditingController(),
              name: TextEditingController(),
              modelId: TextEditingController(),
              apiKey: TextEditingController(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<LanguageModelProvider>));
      await tester.pumpAndSettle();

      expect(find.text('Google AI'), findsNothing);
      expect(find.text('OpenAI-kompatibel'), findsOneWidget);
      expect(find.text('Ollama (lokal)'), findsOneWidget);
    },
  );
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
