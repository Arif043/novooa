import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/runtime/workspace_capabilities.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/employees/domain/repositories/employee_repository.dart';
import 'package:syscat2/features/employees/domain/usecases/watch_employees.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_employee_assignments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_state.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_knowledge_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_knowledge_attachments_state.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_configuration_panel.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_body.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_theme.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _rezeption = Employee(
  id: 'e1',
  name: 'Rezeption',
  constraint: 'Sei freundlich.',
);

void main() {
  setUp(() {
    serviceLocator.registerSingleton(
      const WorkspaceCapabilities(
        assistant: true,
        dataCollections: true,
        modelCatalog: false,
        push: false,
        messagingChannels: false,
        skills: false,
        employees: true,
        plugins: false,
      ),
    );
  });
  tearDown(() => serviceLocator.unregister<WorkspaceCapabilities>());

  testWidgets('einen Mitarbeiter im Sheet wählen weist ihn dem Prompt zu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final builder = TaskBuilderCubit(repository: _Tasks());
    await builder.load(_task);
    final employees = NodeEmployeeAssignmentsCubit(
      _Auth(),
      WatchEmployees(_Employees()),
      GetCurrentTeamId(_Teams()),
    )..load();

    await tester.pumpWidget(_host(builder, employees));
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byTooltip('Mitarbeiter zuweisen'));
    await tester.tap(find.byTooltip('Mitarbeiter zuweisen'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Rezeption').last);
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(tester.takeException(), isNull);
    final config =
        (builder.state as TaskBuilderLoaded).editingTask.nodes.single.config
            as PromptNodeConfig;
    expect(config.employeeId, 'e1');
    expect(find.text('Rahmenbedingung · keine Fähigkeiten'), findsOneWidget);
  });

  testWidgets(
    'auch im echten Konfigurationspanel bleibt die Zuweisung stabil',
    (tester) async {
      tester.view.physicalSize = const Size(1480, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final builder = TaskBuilderCubit(repository: _Tasks());
      await builder.load(_task);
      final employees = NodeEmployeeAssignmentsCubit(
        _Auth(),
        WatchEmployees(_Employees()),
        GetCurrentTeamId(_Teams()),
      )..load();

      await tester.pumpWidget(_panelHost(builder, employees));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('compact-node-prompt')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NodeConfigurationPanel), findsOneWidget);
      final assignButton = find.descendant(
        of: find.byType(NodeConfigurationPanel),
        matching: find.byTooltip('Mitarbeiter zuweisen'),
      );
      await tester.ensureVisible(assignButton);
      await tester.tap(assignButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Rezeption').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      final config =
          (builder.state as TaskBuilderLoaded).editingTask.nodes.single.config
              as PromptNodeConfig;
      expect(config.employeeId, 'e1');
    },
  );
}

Widget _panelHost(
  TaskBuilderCubit builder,
  NodeEmployeeAssignmentsCubit employees,
) {
  return MaterialApp(
    theme: TaskBuilderTheme.from(SyscatTheme.lightTheme),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: builder),
          BlocProvider.value(value: employees),
          BlocProvider<NodeFileAttachmentsCubit>.value(value: _NoFiles()),
          BlocProvider<NodeKnowledgeAttachmentsCubit>.value(value: _NoNotes()),
        ],
        child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
          builder: (_, state) => TaskBuilderBody(state: state),
        ),
      ),
    ),
  );
}

Widget _host(TaskBuilderCubit builder, NodeEmployeeAssignmentsCubit employees) {
  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: builder),
          BlocProvider.value(value: employees),
          BlocProvider<NodeFileAttachmentsCubit>.value(value: _NoFiles()),
          BlocProvider<NodeKnowledgeAttachmentsCubit>.value(value: _NoNotes()),
        ],
        child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
          builder: (context, state) {
            final task = (state as TaskBuilderLoaded).editingTask;
            return SingleChildScrollView(
              child: PromptWidget(node: task.nodes.single),
            );
          },
        ),
      ),
    ),
  );
}

const _task = Task(
  id: 'task',
  title: 'Aufgabe',
  objective: '',
  selectedNodeId: NodeId('prompt'),
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('prompt'),
        title: 'Prompt',
        description: '',
        config: PromptNodeConfig(
          instruction: 'Hallo',
          outputType: PromptOutputType.text,
          choices: ['', ''],
        ),
      ),
    ],
    edges: [],
  ),
);

class _Tasks implements TaskRepository {
  @override
  Future<void> deleteTask(String taskId) async {}
  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => throw UnimplementedError();
  @override
  Stream<List<Task>> watchTasks() => Stream.value(const [_task]);
  @override
  Future<void> saveTask(Task task) async {}
}

class _Auth implements AuthRepository {
  @override
  AuthUser? currentUser() => const AuthUser(
    id: UniqueId('user'),
    email: 'user@example.com',
    displayName: 'Nutzer',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Employees implements EmployeeRepository {
  @override
  Stream<List<Employee>> watchEmployees(TeamId teamId) =>
      Stream.value(const [_rezeption]);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoFiles extends Cubit<NodeFileAttachmentsState>
    implements NodeFileAttachmentsCubit {
  _NoFiles() : super(const NodeFileAttachmentsState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoNotes extends Cubit<NodeKnowledgeAttachmentsState>
    implements NodeKnowledgeAttachmentsCubit {
  _NoNotes() : super(const NodeKnowledgeAttachmentsState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
