import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection_draft.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_provider.dart';
import 'package:syscat2/features/language_models/domain/repositories/language_model_connection_repository.dart';
import 'package:syscat2/features/language_models/domain/usecases/remove_language_model_connection.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_model_connections.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_state.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  test('lädt verbundene Anbieter für das aktuelle Team', () async {
    final repository = _Connections(
      connections: const [
        LanguageModelConnection(
          id: 'connection-1',
          name: 'Google AI',
          provider: LanguageModelProvider.googleAi,
        ),
      ],
    );
    final cubit = _cubit(repository);

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, LanguageModelConnectionsStatus.ready);
    expect(cubit.state.connections.single.name, 'Google AI');
    await cubit.close();
  });

  test('entfernt eine Verbindung über das Repository', () async {
    final repository = _Connections(connections: const []);
    final cubit = _cubit(repository);
    await cubit.load();

    await cubit.removeConnection('connection-1');

    expect(repository.removedConnectionId, 'connection-1');
    expect(cubit.state.message, 'Verbindung entfernt.');
    await cubit.close();
  });
}

LanguageModelConnectionsCubit _cubit(_Connections repository) {
  return LanguageModelConnectionsCubit(
    _Auth(),
    WatchLanguageModelConnections(repository),
    RemoveLanguageModelConnection(repository),
    GetCurrentTeamId(_Teams()),
  );
}

class _Connections implements LanguageModelConnectionRepository {
  _Connections({required this.connections});

  final List<LanguageModelConnection> connections;
  String? removedConnectionId;

  @override
  Future<void> connectLanguageModels(LanguageModelConnectionDraft draft) =>
      throw UnimplementedError();

  @override
  Stream<List<LanguageModelConnection>> watchConnections(TeamId teamId) =>
      Stream.value(connections);

  @override
  Future<void> removeConnection(TeamId teamId, String connectionId) async {
    removedConnectionId = connectionId;
  }
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
