import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/domain/entities/connection_draft.dart';
import 'package:syscat2/features/connections/domain/entities/connection_failure.dart';
import 'package:syscat2/features/connections/domain/entities/connection_test_result.dart';
import 'package:syscat2/features/connections/domain/repositories/connection_repository.dart';
import 'package:syscat2/features/connections/domain/usecases/connection_use_cases.dart';
import 'package:syscat2/features/connections/infrastructure/repositories/connection_json_mapper.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_state.dart';
import 'package:syscat2/features/connections/presentation/widgets/connection_editor_dialog.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _shop = Connection(
  id: 'c1',
  name: 'Shop',
  baseUrl: 'https://shop.example.com/api',
  auth: BearerAuth(),
  updatedAt: '2026-10-05T10:00:00.000Z',
);

void main() {
  group('JSON-Abbildung', () {
    test('alle Anmeldearten laufen verlustfrei hin und zurück', () {
      for (final auth in const <ConnectionAuth>[
        ApiKeyAuth(headerName: 'X-API-Key'),
        BearerAuth(),
        OAuthClientCredentialsAuth(
          tokenUrl: 'https://shop.example.com/api/oauth/token',
          clientId: 'client-1',
          scope: 'write',
        ),
      ]) {
        expect(authFromJson(authToJson(auth)), auth);
      }
    });

    test('ein leerer Scope wird nicht gesendet', () {
      final json = authToJson(
        const OAuthClientCredentialsAuth(
          tokenUrl: 'https://t.example/token',
          clientId: 'abc',
        ),
      );

      expect(json.containsKey('scope'), isFalse);
    });

    test('das Geheimnis wird nur gesendet, wenn eines eingegeben wurde', () {
      const draft = ConnectionDraft(
        name: ' Shop ',
        baseUrl: ' https://shop.example.com ',
        auth: BearerAuth(),
      );

      final without = draftToJson(draft);
      final withSecret = draftToJson(
        const ConnectionDraft(
          name: 'Shop',
          baseUrl: 'https://shop.example.com',
          auth: BearerAuth(),
          secret: '  geheim ',
        ),
      );

      expect(without['name'], 'Shop');
      expect(without['baseUrl'], 'https://shop.example.com');
      expect(without.containsKey('secret'), isFalse);
      expect(withSecret['secret'], 'geheim');
    });

    test('Antworten werden gelesen; eine unbekannte Anmeldeart ist ein Fehler',
        () {
      final connection = connectionFromJson({
        'id': 'c1',
        'name': 'Shop',
        'baseUrl': 'https://shop.example.com/api',
        'auth': {'kind': 'bearer'},
        'updatedAt': 'x',
      });

      expect(connection.auth, const BearerAuth());
      expect(
        () => authFromJson({'kind': 'basic'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        testResultFromJson({'ok': true, 'message': 'Läuft.'}),
        const ConnectionTestResult(ok: true, message: 'Läuft.'),
      );
    });
  });

  group('ConnectionsCubit', () {
    test('zeigt die gespeicherten Verbindungen', () async {
      final cubit = _cubit(_Repository(connections: const [_shop]));

      await cubit.load();
      await pumpEventQueue();

      expect(cubit.state.status, ConnectionsStatus.ready);
      expect(cubit.state.connections, [_shop]);
      await cubit.close();
    });

    test('Speichern legt an, ändert und meldet Erfolg', () async {
      final repository = _Repository();
      final cubit = _cubit(repository);
      const draft = ConnectionDraft(
        name: 'Shop',
        baseUrl: 'https://shop.example.com/api',
        auth: BearerAuth(),
        secret: 'geheim',
      );

      expect(await cubit.save(draft), isNull);
      expect(repository.created, [draft]);
      expect(cubit.state.message, 'Verbindung „Shop“ gespeichert.');

      expect(await cubit.save(draft, id: 'c1'), isNull);
      expect(repository.updated, [('c1', draft)]);
      await cubit.close();
    });

    test('ein Fehler beim Speichern kommt als Meldung zurück, nicht als Snackbar',
        () async {
      final cubit = _cubit(
        _Repository(
          saveResult: const Error(ConnectionFailure('Die Basis-URL ist ungültig.')),
        ),
      );

      final error = await cubit.save(
        const ConnectionDraft(name: 'x', baseUrl: 'y', auth: BearerAuth()),
      );

      expect(error, 'Die Basis-URL ist ungültig.');
      expect(cubit.state.message, isNull);
      await cubit.close();
    });

    test('Löschen meldet den Namen; Fehler werden gemeldet', () async {
      final repository = _Repository(connections: const [_shop]);
      final cubit = _cubit(repository);
      await cubit.load();
      await pumpEventQueue();

      await cubit.delete('c1');

      expect(repository.deleted, ['c1']);
      expect(cubit.state.message, 'Verbindung „Shop“ gelöscht.');
      cubit.messageShown();
      expect(cubit.state.message, isNull);

      final failing = _cubit(
        _Repository(deleteResult: const Error(ConnectionFailure.deleteFailed)),
      );
      await failing.delete('c1');
      expect(failing.state.message, ConnectionFailure.deleteFailed.message);
      await cubit.close();
      await failing.close();
    });

    test('ein fehlgeschlagener Test ist ein Ergebnis, keine Ausnahme', () async {
      final ok = _cubit(
        _Repository(
          testResult: const Success(
            ConnectionTestResult(ok: true, message: 'Funktioniert.'),
          ),
        ),
      );
      final broken = _cubit(
        _Repository(testResult: const Error(ConnectionFailure.testFailed)),
      );

      expect((await ok.test('c1', path: '/ping')).ok, isTrue);
      final result = await broken.test('c1');
      expect(result.ok, isFalse);
      expect(result.message, ConnectionFailure.testFailed.message);
      await ok.close();
      await broken.close();
    });
  });

  group('ConnectionEditorDialog', () {
    Future<_Repository> open(
      WidgetTester tester, {
      Connection? existing,
      _Repository? repository,
    }) async {
      final target = repository ?? _Repository();
      final cubit = _cubit(target);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => ConnectionEditorDialog.show(
                  context,
                  cubit: cubit,
                  existing: existing,
                ),
                child: const Text('öffnen'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();
      return target;
    }

    Future<void> enter(WidgetTester tester, String label, String text) async {
      await tester.enterText(find.widgetWithText(TextField, label), text);
      await tester.pump();
    }

    testWidgets('prüft Pflichtfelder der Reihe nach, bevor etwas gesendet wird',
        (tester) async {
      final repository = await open(tester);

      await tester.tap(find.text('Speichern'));
      await tester.pump();
      expect(find.text('Bitte gib einen Namen an.'), findsOneWidget);

      await enter(tester, 'Name', 'Shop');
      await tester.tap(find.text('Speichern'));
      await tester.pump();
      expect(find.textContaining('Basis-URL muss mit https://'), findsOneWidget);

      await enter(tester, 'Basis-URL', 'https://shop.example.com/api');
      await tester.tap(find.text('Speichern'));
      await tester.pump();
      expect(find.text('Bitte gib das API-Key an.'), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('speichert einen API-Key mit dem eingegebenen Header', (tester) async {
      final repository = await open(tester);

      await enter(tester, 'Name', 'Shop');
      await enter(tester, 'Basis-URL', 'https://shop.example.com/api');
      await enter(tester, 'API-Key', 'k-123');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(repository.created.single, const ConnectionDraft(
        name: 'Shop',
        baseUrl: 'https://shop.example.com/api',
        auth: ApiKeyAuth(headerName: 'X-API-Key'),
        secret: 'k-123',
      ));
      expect(find.byType(ConnectionEditorDialog), findsNothing);
    });

    testWidgets('OAuth zeigt Token-URL, Client-ID und Scope und verlangt das Client-Secret',
        (tester) async {
      final repository = await open(tester);
      await enter(tester, 'Name', 'Shop');
      await enter(tester, 'Basis-URL', 'https://shop.example.com/api');

      await tester.tap(find.byKey(const ValueKey('connection-auth-kind')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OAuth (Client Credentials)').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pump();
      expect(find.textContaining('Token-URL muss'), findsOneWidget);

      await enter(tester, 'Token-URL', 'https://shop.example.com/api/oauth/token');
      await enter(tester, 'Client-ID', 'client-1');
      await tester.tap(find.text('Speichern'));
      await tester.pump();
      expect(find.text('Bitte gib das Client-Secret an.'), findsOneWidget);

      await enter(tester, 'Client-Secret', 's3');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(repository.created.single.auth, const OAuthClientCredentialsAuth(
        tokenUrl: 'https://shop.example.com/api/oauth/token',
        clientId: 'client-1',
      ));
    });

    testWidgets('http:// warnt vor unverschlüsselten Zugangsdaten', (tester) async {
      await open(tester);
      expect(find.textContaining('unverschlüsselt'), findsNothing);

      await enter(tester, 'Basis-URL', 'http://localhost:8080');

      expect(find.textContaining('unverschlüsselt'), findsOneWidget);
    });

    testWidgets('beim Ändern bleibt das Geheimnis leer und wird nicht mitgeschickt; Testen ist möglich',
        (tester) async {
      final repository = _Repository(
        testResult: const Success(
          ConnectionTestResult(ok: true, message: 'Verbindung funktioniert (Status 200).'),
        ),
      );
      await open(tester, existing: _shop, repository: repository);
      expect(find.text('Gespeichert – leer lassen, um es zu behalten.'), findsOneWidget);

      await enter(tester, 'Test-Pfad (optional)', '/ping');
      await tester.ensureVisible(find.text('Testen'));
      await tester.tap(find.text('Testen'));
      await tester.pumpAndSettle();
      expect(find.text('Verbindung funktioniert (Status 200).'), findsOneWidget);
      expect(repository.tested, [('c1', '/ping')]);

      await enter(tester, 'Name', 'Shop neu');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      final (id, draft) = repository.updated.single;
      expect(id, 'c1');
      expect(draft.name, 'Shop neu');
      expect(draft.secret, isEmpty);
    });

    testWidgets('ein Wechsel der Anmeldeart verlangt ein neues Geheimnis', (tester) async {
      await open(tester, existing: _shop);

      await tester.tap(find.byKey(const ValueKey('connection-auth-kind')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('API-Key im Header').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pump();

      expect(find.text('Bitte gib das API-Key an.'), findsOneWidget);
    });

    testWidgets('Fehler des Servers erscheinen im Editor, der offen bleibt', (tester) async {
      final repository = _Repository(
        saveResult: const Error(ConnectionFailure('Der Name ist vergeben.')),
      );
      await open(tester, repository: repository);
      await enter(tester, 'Name', 'Shop');
      await enter(tester, 'Basis-URL', 'https://shop.example.com');
      await enter(tester, 'API-Key', 'k');

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Der Name ist vergeben.'), findsOneWidget);
      expect(find.byType(ConnectionEditorDialog), findsOneWidget);
    });
  });
}

ConnectionsCubit _cubit(_Repository repository) => ConnectionsCubit(
  WatchConnections(repository),
  CreateConnection(repository),
  UpdateConnection(repository),
  DeleteConnection(repository),
  TestConnection(repository),
  GetCurrentTeamId(_Teams()),
);

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Repository implements ConnectionRepository {
  _Repository({
    this.connections = const [],
    this.saveResult,
    this.deleteResult = const Success(unit),
    this.testResult = const Success(ConnectionTestResult(ok: true, message: 'ok')),
  });

  final List<Connection> connections;
  final Result<Connection, ConnectionFailure>? saveResult;
  final Result<Unit, ConnectionFailure> deleteResult;
  final Result<ConnectionTestResult, ConnectionFailure> testResult;
  final created = <ConnectionDraft>[];
  final updated = <(String, ConnectionDraft)>[];
  final deleted = <String>[];
  final tested = <(String, String)>[];

  @override
  Stream<List<Connection>> watchConnections(TeamId teamId) =>
      Stream.value(connections);

  @override
  Future<Result<Connection, ConnectionFailure>> create(ConnectionDraft draft) async {
    created.add(draft);
    return saveResult ?? Success(_shop.copyNamed(draft.name));
  }

  @override
  Future<Result<Connection, ConnectionFailure>> update(String id, ConnectionDraft draft) async {
    updated.add((id, draft));
    return saveResult ?? Success(_shop.copyNamed(draft.name));
  }

  @override
  Future<Result<Unit, ConnectionFailure>> delete(String id) async {
    deleted.add(id);
    return deleteResult;
  }

  @override
  Future<Result<ConnectionTestResult, ConnectionFailure>> test(String id, {String path = ''}) async {
    tested.add((id, path));
    return testResult;
  }
}

extension on Connection {
  Connection copyNamed(String name) => Connection(
    id: id, name: name, baseUrl: baseUrl, auth: auth, updatedAt: updatedAt,
  );
}
