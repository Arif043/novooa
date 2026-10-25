import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_provider.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_repository.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_connection_repository.dart';
import 'package:syscat2/features/language_models/domain/usecases/connect_language_models.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import 'package:syscat2/features/settings/presentation/widgets/language_model_connect_form.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  testWidgets('blendet bereits verbundene direkte Anbieter im Dropdown aus, '
      'lässt OpenAI-kompatibel aber immer wählbar', (tester) async {
    final cubit = LanguageModelsSettingsCubit(
      _Auth(),
      WatchLanguageModels(_Models()),
      GetCurrentTeamId(_Teams()),
      ConnectLanguageModels(_Connections()),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageModelConnectForm(
            cubit: cubit,
            state: cubit.state,
            connections: const [
              LanguageModelConnection(
                id: 'connection-1',
                name: 'Google AI',
                provider: LanguageModelProvider.googleAi,
              ),
            ],
            baseUrl: TextEditingController(),
            apiKey: TextEditingController(),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byType(DropdownButtonFormField<LanguageModelProvider>),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google AI'), findsNothing);
    expect(find.text('OpenAI-kompatibel'), findsOneWidget);
    expect(find.text('Ollama (lokal)'), findsOneWidget);
  });
}

class _Connections implements LanguageModelConnectionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Models implements LanguageModelRepository {
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
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team');
}
