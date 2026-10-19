import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/employees/domain/entities/employee_draft.dart';
import 'package:syscat2/features/employees/domain/entities/employee_failure.dart';
import 'package:syscat2/features/employees/domain/repositories/employee_repository.dart';
import 'package:syscat2/features/employees/domain/usecases/employee_use_cases.dart';
import 'package:syscat2/features/employees/domain/usecases/watch_employees.dart';
import 'package:syscat2/features/employees/infrastructure/repositories/local_employee_repository.dart';
import 'package:syscat2/features/employees/presentation/cubits/employees_cubit.dart';
import 'package:syscat2/features/employees/presentation/cubits/employees_state.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/employee_assignment_picker.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';
import 'package:syscat2/features/employees/presentation/widgets/employee_avatar.dart';

const _rezeption = Employee(
  id: 'e1',
  name: 'Rezeption',
  constraint: 'Sei freundlich.',
  skillNames: ['pdf', 'mails'],
);

void main() {
  group('LocalEmployeeRepository', () {
    test(
      'sendet Entwürfe im Wire-Format und liest den Mitarbeiter zurück',
      () async {
        final client = _Api({
          'POST /v1/employees': _json(_rezeption),
          'PUT /v1/employees/e%201': _json(_rezeption),
        });
        final repository = LocalEmployeeRepository(client, _FakeChannel());
        const draft = EmployeeDraft(
          name: 'Rezeption',
          constraint: 'Sei freundlich.',
          skillNames: ['pdf', 'mails'],
        );

        final created = await repository.createEmployee(draft);
        final updated = await repository.updateEmployee('e 1', draft);

        expect(client.bodies.first, {
          'name': 'Rezeption',
          'constraint': 'Sei freundlich.',
          'skills': ['pdf', 'mails'],
        });
        expect(created.tryGetSuccess(), _rezeption);
        expect(updated.tryGetSuccess()?.skillNames, ['pdf', 'mails']);
      },
    );

    test('Löschen kodiert die ID; Serverfehler werden zur Meldung', () async {
      final client = _Api(
        {},
        failures: {
          'DELETE /v1/employees/gibt-es-nicht': WorkspaceHttpException(
            404,
            const WorkspaceApiError(
              message: 'Der Mitarbeiter wurde nicht gefunden.',
            ),
          ),
          'POST /v1/employees': WorkspaceHttpException(
            409,
            const WorkspaceApiError(
              message: 'Es gibt schon einen Mitarbeiter mit dem Namen „X“.',
            ),
          ),
        },
      );
      final repository = LocalEmployeeRepository(client, _FakeChannel());

      final deleted = await repository.deleteEmployee('gibt-es-nicht');
      final created = await repository.createEmployee(
        const EmployeeDraft(name: 'X', constraint: ''),
      );

      expect(
        deleted.tryGetError()?.message,
        'Der Mitarbeiter wurde nicht gefunden.',
      );
      expect(
        created.tryGetError()?.message,
        contains('schon einen Mitarbeiter'),
      );
    });

    test(
      'unbekannte Fehler fallen auf eine allgemeine Meldung zurück',
      () async {
        final repository = LocalEmployeeRepository(
          _Api({}, failures: {'POST /v1/employees': StateError('offline')}),
          _FakeChannel(),
        );

        final result = await repository.createEmployee(
          const EmployeeDraft(name: 'X', constraint: ''),
        );

        expect(
          result.tryGetError()?.message,
          'Mitarbeiter konnte nicht gespeichert werden.',
        );
      },
    );
  });

  group('EmployeesCubit', () {
    test('lädt die Liste und meldet Speichern, Fehler und Löschen', () async {
      final repository = _Repository();
      final cubit = _cubit(repository);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, EmployeesStatus.ready);
      expect(cubit.state.employees, [_rezeption]);

      expect(
        await cubit.save(const EmployeeDraft(name: 'Neu', constraint: '')),
        isTrue,
      );
      expect(cubit.state.message, 'Mitarbeiter gespeichert.');
      cubit.messageShown();
      expect(cubit.state.message, isNull);

      repository.saveFailure = const EmployeeFailure(
        'Es gibt schon einen Mitarbeiter mit dem Namen „Neu“.',
      );
      expect(
        await cubit.save(const EmployeeDraft(name: 'Neu', constraint: '')),
        isFalse,
      );
      expect(cubit.state.message, contains('schon einen Mitarbeiter'));

      await cubit.delete('e1');
      expect(repository.deleted, ['e1']);
      expect(cubit.state.message, 'Mitarbeiter gelöscht.');
    });

    test('Bearbeiten ruft update mit der ID auf', () async {
      final repository = _Repository();
      final cubit = _cubit(repository);

      await cubit.save(
        const EmployeeDraft(name: 'Neu', constraint: ''),
        employeeId: 'e1',
      );

      expect(repository.updatedIds, ['e1']);
      expect(repository.created, isEmpty);
    });

    test('ein Ladefehler zeigt den Fehlerzustand', () async {
      final cubit = _cubit(_Repository()..watchError = true);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, EmployeesStatus.failure);
    });
  });

  group('EmployeeAssignmentPicker', () {
    Future<void> pump(
      WidgetTester tester, {
      String? assignedId,
      bool enabled = true,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmployeeAssignmentPicker(
              assignedId: assignedId,
              employees: const [_rezeption],
              enabled: enabled,
              onAssign: (_) {},
              onUnassign: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('ohne Zuweisung steht dort, dass keiner zugewiesen ist', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Kein Mitarbeiter zugewiesen.'), findsOneWidget);
    });

    testWidgets('zeigt Name und Anzahl der Fähigkeiten aus der Live-Liste', (
      tester,
    ) async {
      await pump(tester, assignedId: 'e1');

      expect(find.text('Rezeption'), findsWidgets);
      expect(find.text('Rahmenbedingung · 2 Fähigkeiten'), findsOneWidget);
      expect(
        tester.widget<EmployeeAvatar>(find.byType(EmployeeAvatar)).employeeId,
        'e1',
      );
    });

    testWidgets(
      'ein gelöschter Mitarbeiter wird als nicht mehr vorhanden gemeldet',
      (tester) async {
        await pump(tester, assignedId: 'weg');

        expect(find.text('Mitarbeiter nicht mehr vorhanden'), findsOneWidget);
        expect(find.text('Wähle einen anderen Mitarbeiter.'), findsOneWidget);
        expect(find.byType(EmployeeAvatar), findsNothing);
      },
    );

    testWidgets(
      'solange die Liste lädt, wird nichts voreilig als fehlend gemeldet',
      (tester) async {
        await pump(tester, assignedId: 'weg', enabled: false);

        expect(find.text('Mitarbeiter nicht mehr vorhanden'), findsNothing);
      },
    );
  });
}

EmployeesCubit _cubit(_Repository repository) => EmployeesCubit(
  WatchEmployees(repository),
  CreateEmployee(repository),
  UpdateEmployee(repository),
  DeleteEmployee(repository),
  GetCurrentTeamId(_Teams()),
);

Map<String, Object?> _json(Employee employee) => {
  'id': employee.id,
  'name': employee.name,
  'constraint': employee.constraint,
  'skills': employee.skillNames,
};

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Repository implements EmployeeRepository {
  EmployeeFailure? saveFailure;
  bool watchError = false;
  final created = <EmployeeDraft>[];
  final updatedIds = <String>[];
  final deleted = <String>[];

  @override
  Stream<List<Employee>> watchEmployees(TeamId teamId) {
    if (watchError) return Stream.error(StateError('kaputt'));
    return Stream.value(const [_rezeption]);
  }

  @override
  Future<Result<Employee, EmployeeFailure>> createEmployee(
    EmployeeDraft draft,
  ) async {
    final failure = saveFailure;
    if (failure != null) return Error(failure);
    created.add(draft);
    return const Success(_rezeption);
  }

  @override
  Future<Result<Employee, EmployeeFailure>> updateEmployee(
    String employeeId,
    EmployeeDraft draft,
  ) async {
    updatedIds.add(employeeId);
    return const Success(_rezeption);
  }

  @override
  Future<Result<Unit, EmployeeFailure>> deleteEmployee(
    String employeeId,
  ) async {
    deleted.add(employeeId);
    return const Success(unit);
  }
}

class _Api implements WorkspaceApiClient {
  _Api(this.responses, {this.failures = const {}});

  final Map<String, Map<String, Object?>> responses;
  final Map<String, Object> failures;
  final bodies = <Map<String, Object?>>[];

  Future<Map<String, Object?>> _answer(String key) async {
    final failure = failures[key];
    if (failure != null) throw failure;
    return responses[key] ?? (throw StateError('Keine Antwort für $key'));
  }

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) {
    bodies.add(body);
    return _answer('POST $path');
  }

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) {
    bodies.add(body);
    return _answer('PUT $path');
  }

  @override
  Future<Map<String, Object?>> delete(String path) async {
    final failure = failures['DELETE $path'];
    if (failure != null) throw failure;
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeChannel implements WorkspaceRealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
