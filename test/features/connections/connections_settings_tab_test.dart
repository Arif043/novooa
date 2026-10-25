import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/domain/entities/connection_draft.dart';
import 'package:syscat2/features/connections/domain/entities/connection_failure.dart';
import 'package:syscat2/features/connections/domain/entities/connection_test_result.dart';
import 'package:syscat2/features/connections/domain/repositories/connection_repository.dart';
import 'package:syscat2/features/connections/domain/usecases/connection_use_cases.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/connections/presentation/widgets/connection_editor_dialog.dart';
import 'package:syscat2/features/connections/presentation/widgets/connections_settings_tab.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _shop = Connection(
  id: 'c1',
  name: 'Shop',
  baseUrl: 'https://shop.example.com/api',
  auth: ApiKeyAuth(headerName: 'X-API-Key'),
  updatedAt: 'x',
);

void main() {
  late _Repository repository;

  setUp(() {
    repository = _Repository();
    final teams = GetCurrentTeamId(_Teams());
    serviceLocator.registerFactory(
      () => ConnectionsCubit(
        WatchConnections(repository),
        CreateConnection(repository),
        UpdateConnection(repository),
        DeleteConnection(repository),
        TestConnection(repository),
        teams,
      ),
    );
  });

  tearDown(serviceLocator.reset);

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectionsSettingsTab())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ohne Verbindungen steht ein Hinweis da', (tester) async {
    await pumpTab(tester);

    expect(find.text('Noch keine Verbindungen angelegt.'), findsOneWidget);
    expect(find.text('Verbindung hinzufügen'), findsOneWidget);
  });

  testWidgets(
    'listet Verbindungen mit Adresse und Anmeldeart, nie mit Geheimnis',
    (tester) async {
      repository.connections = const [_shop];
      await pumpTab(tester);

      expect(find.text('Shop'), findsOneWidget);
      expect(
        find.text('https://shop.example.com/api · API-Key im Header'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Antippen öffnet den Editor mit den gespeicherten Werten', (
    tester,
  ) async {
    repository.connections = const [_shop];
    await pumpTab(tester);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(find.byType(ConnectionEditorDialog), findsOneWidget);
    expect(find.text('Verbindung bearbeiten'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
  });

  testWidgets('Löschen verlangt eine Bestätigung', (tester) async {
    repository.connections = const [_shop];
    await pumpTab(tester);

    await tester.tap(find.byTooltip('Verbindung löschen'));
    await tester.pumpAndSettle();
    expect(find.text('„Shop“ löschen?'), findsOneWidget);
    expect(repository.deleted, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(repository.deleted, ['c1']);
  });
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');
}

class _Repository implements ConnectionRepository {
  List<Connection> connections = const [];
  final deleted = <String>[];

  @override
  Stream<List<Connection>> watchConnections(TeamId teamId) =>
      Stream.value(connections);

  @override
  Future<Result<Connection, ConnectionFailure>> create(
    ConnectionDraft draft,
  ) async => const Success(_shop);

  @override
  Future<Result<Connection, ConnectionFailure>> update(
    String id,
    ConnectionDraft draft,
  ) async => const Success(_shop);

  @override
  Future<Result<Unit, ConnectionFailure>> delete(String id) async {
    deleted.add(id);
    return const Success(unit);
  }

  @override
  Future<Result<ConnectionTestResult, ConnectionFailure>> test(
    String id, {
    String path = '',
  }) async => const Success(ConnectionTestResult(ok: true, message: 'ok'));
}
