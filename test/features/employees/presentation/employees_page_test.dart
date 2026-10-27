import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/widgets/luminous_card.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/employees/domain/entities/employee_draft.dart';
import 'package:syscat2/features/employees/domain/entities/employee_failure.dart';
import 'package:syscat2/features/employees/domain/repositories/employee_repository.dart';
import 'package:syscat2/features/employees/domain/usecases/employee_use_cases.dart';
import 'package:syscat2/features/employees/domain/usecases/watch_employees.dart';
import 'package:syscat2/features/employees/presentation/cubits/employees_cubit.dart';
import 'package:syscat2/features/employees/presentation/pages/employees_page.dart';
import 'package:syscat2/features/employees/presentation/widgets/employee_avatar.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _reception = Employee(
  id: 'e-1',
  name: 'Rezeption',
  constraint: 'Du begrüßt Gäste freundlich.',
  skillNames: ['pdf', 'word'],
);
const _archive = Employee(id: 'e-2', name: 'Archiv', constraint: '');

void main() {
  testWidgets('zeigt Mitarbeiter als Karten mit Avatar und Zusammenfassung', (
    tester,
  ) async {
    await _pumpPage(tester, _Repository(const [_reception, _archive]));

    expect(find.text('Spezialisten für deine Prompt-Bausteine.'), findsOne);
    expect(find.text('2 Mitarbeiter'), findsOneWidget);
    expect(find.byType(LuminousCard), findsNWidgets(2));
    expect(find.byType(EmployeeAvatar), findsNWidgets(2));
    expect(find.text('Du begrüßt Gäste freundlich.'), findsOneWidget);
    expect(find.text('2 Fähigkeiten'), findsOneWidget);
    expect(find.text('Keine Fähigkeiten'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Mitarbeiter anlegen'),
      findsOneWidget,
    );
  });

  testWidgets('lädt ohne Mitarbeiter den leeren Zustand mit einer Aktion', (
    tester,
  ) async {
    await _pumpPage(tester, _Repository(const []));

    expect(find.text('Noch keine Mitarbeiter'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Mitarbeiter anlegen'),
      findsOneWidget,
    );
    expect(find.byType(LuminousCard), findsNothing);
  });

  testWidgets('bietet bei einem Ladefehler „Erneut versuchen“ an', (
    tester,
  ) async {
    await _pumpPage(tester, _Repository(const [], fails: true));

    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('löscht einen Mitarbeiter erst nach Bestätigung', (tester) async {
    final repository = _Repository(const [_reception]);
    await _pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Mitarbeiter „Rezeption“ löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Mitarbeiter löschen?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);

    await tester.tap(find.byTooltip('Mitarbeiter „Rezeption“ löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(repository.deleted, ['e-1']);
  });
}

Future<void> _pumpPage(WidgetTester tester, _Repository repository) async {
  final cubit = EmployeesCubit(
    WatchEmployees(repository),
    CreateEmployee(repository),
    UpdateEmployee(repository),
    DeleteEmployee(repository),
    GetCurrentTeamId(_Teams()),
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(value: cubit, child: const EmployeesView()),
      ),
    ),
  );
  await cubit.load();
  await tester.pumpAndSettle();
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');
}

class _Repository implements EmployeeRepository {
  _Repository(this.employees, {this.fails = false});

  final List<Employee> employees;
  final bool fails;
  final deleted = <String>[];

  @override
  Stream<List<Employee>> watchEmployees(TeamId teamId) =>
      fails ? Stream.error(StateError('kaputt')) : Stream.value(employees);

  @override
  Future<Result<Employee, EmployeeFailure>> createEmployee(
    EmployeeDraft draft,
  ) => throw UnimplementedError();

  @override
  Future<Result<Employee, EmployeeFailure>> updateEmployee(
    String employeeId,
    EmployeeDraft draft,
  ) => throw UnimplementedError();

  @override
  Future<Result<Unit, EmployeeFailure>> deleteEmployee(String id) async {
    deleted.add(id);
    return const Success(unit);
  }
}
