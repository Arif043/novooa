import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/file_failure.dart';
import 'package:syscat2/features/files/domain/entities/team_file.dart';
import 'package:syscat2/features/files/domain/entities/team_folder.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/domain/entities/upload_file_input.dart';
import 'package:syscat2/features/files/domain/repositories/team_file_repository.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_files.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_failure.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note_draft.dart';
import 'package:syscat2/features/knowledge_base/domain/repositories/knowledge_base_repository.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_knowledge_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_pager.dart';
import 'package:syscat2/features/teams/domain/entities/team_member.dart';
import 'package:syscat2/features/teams/domain/entities/team_workspace.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  testWidgets('bleibt nach Branch-Mutation auf der Branch-Seite', (
    tester,
  ) async {
    final node = _conditionalNode();
    await tester.pumpWidget(await _app(_taskFor(node), node));
    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fall:'), findsOneWidget);

    final updatedNode = _conditionalNode(branchGraph: _promptGraph());
    await tester.pumpWidget(await _app(_taskFor(updatedNode), updatedNode));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fall:'), findsOneWidget);
    expect(find.text('Prompt'), findsOneWidget);
    expect(find.text('Wenn'), findsNothing);
  });

  testWidgets(
    'zeigt einen Hinweis statt der Wenn-Eingabe, wenn der direkte '
    'Vorgänger ein Entscheidungs-Prompt ist',
    (tester) async {
      final node = _conditionalNode();
      final task = _taskFor(
        node,
        precedingPrompt: const WorkflowNode(
          id: NodeId('prompt.1'),
          title: 'Prompt',
          description: '',
          outputName: 'entscheidung',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.decision,
            choices: ['Ja'],
          ),
        ),
      );
      await tester.pumpWidget(await _app(task, node));

      expect(find.text('Wenn'), findsNothing);
      expect(
        find.text(
          'Die Verzweigungen werden aus dem vorherigen Prompt-Baustein '
          'ermittelt.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'zeigt die normale Wenn-Eingabe, wenn kein Entscheidungs-Prompt '
    'direkt vorausgeht',
    (tester) async {
      final node = _conditionalNode();
      await tester.pumpWidget(await _app(_taskFor(node), node));

      expect(find.text('Wenn'), findsOneWidget);
    },
  );
}

Future<Widget> _app(Task task, WorkflowNode node) async {
  final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(task));
  await cubit.load(task);
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider(
          create: (_) => NodeFileAttachmentsCubit(
            _FakeAuthRepository(),
            WatchTeamFiles(_FakeTeamFileRepository()),
            GetCurrentTeamId(_FakeTeamRepository()),
          )..load(),
        ),
        BlocProvider(
          create: (_) => NodeKnowledgeAttachmentsCubit(
            _FakeAuthRepository(),
            WatchKnowledgeNotes(_FakeKnowledgeBaseRepository()),
            GetCurrentTeamId(_FakeTeamRepository()),
          )..load(),
        ),
      ],
      child: Scaffold(body: ConditionalPager(node: node)),
    ),
  );
}

Task _taskFor(WorkflowNode conditionalNode, {WorkflowNode? precedingPrompt}) {
  final nodes = [?precedingPrompt, conditionalNode];
  final edges = [
    if (precedingPrompt != null)
      WorkflowEdge(from: precedingPrompt.id, to: conditionalNode.id),
  ];
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: conditionalNode.id,
    graph: WorkflowGraph(nodes: nodes, edges: edges),
  );
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository(this.task);

  Task task;

  @override
  Stream<List<Task>> watchTasks() => Stream.value([task]);

  @override
  Future<void> saveTask(Task value) async => task = value;

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    return const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
  }
}

class _FakeTeamRepository implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team.1');

  @override
  Stream<TeamId> watchCurrentTeamId() => Stream.value(const TeamId('team.1'));

  @override
  Stream<TeamWorkspace> watchCurrentTeam() => const Stream.empty();

  @override
  Stream<List<TeamMember>> watchCurrentTeamMembers() => const Stream.empty();

  @override
  Future<void> updateCurrentTeamName(String name) async {}

  @override
  Future<void> addCurrentTeamMember(String identifier) async {}

  @override
  Future<void> removeCurrentTeamMember(String uid) async {}
}

WorkflowNode _conditionalNode({WorkflowGraph? branchGraph}) {
  return WorkflowNode(
    id: const NodeId('node.1'),
    title: 'Verzweigung',
    description: 'Beschreibung',
    config: ConditionalNodeConfig(
      branches: [
        ConditionalBranch(
          id: 'branch.yes',
          label: 'Ja',
          graph: branchGraph ?? WorkflowGraph.empty(),
        ),
      ],
    ),
  );
}

class _FakeTeamFileRepository implements TeamFileRepository {
  @override
  Stream<List<TeamFile>> watchFiles(TeamId teamId) => Stream.value(const []);

  @override
  Stream<List<TeamFolder>> watchFolders(TeamId teamId) =>
      Stream.value(const []);

  @override
  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
    required String? folderId,
  }) async {
    return const Result.error(FileFailure(FileFailureKind.uploadFailed));
  }

  @override
  Future<Result<TeamFolder, FileFailure>> createFolder({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  }) async {
    return const Result.error(FileFailure(FileFailureKind.createFolderFailed));
  }
}

class _FakeKnowledgeBaseRepository implements KnowledgeBaseRepository {
  @override
  Stream<List<KnowledgeNote>> watchNotes(TeamId teamId) {
    return Stream.value(const []);
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> createNote({
    required TeamId teamId,
    required String ownerUid,
    required KnowledgeNoteDraft draft,
  }) async {
    return const Result.error(
      KnowledgeFailure(KnowledgeFailureKind.saveFailed),
    );
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> updateNote({
    required TeamId teamId,
    required String noteId,
    required KnowledgeNoteDraft draft,
  }) async {
    return const Result.error(
      KnowledgeFailure(KnowledgeFailureKind.saveFailed),
    );
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> restoreNote({
    required TeamId teamId,
    required KnowledgeNote note,
  }) async {
    return Result.success(note);
  }

  @override
  Future<Result<Unit, KnowledgeFailure>> deleteNote({
    required TeamId teamId,
    required String noteId,
  }) async {
    return const Result.success(unit);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  AuthUser? currentUser() {
    return const AuthUser(
      id: UniqueId('user.1'),
      email: 'ada@example.com',
      displayName: 'Ada',
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    return const Result.error(AuthFailure(AuthFailureKind.unknown));
  }

  @override
  Future<Result<Unit, AuthFailure>> signOut() async {
    return const Result.success(unit);
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    return const Result.error(AuthFailure(AuthFailureKind.unknown));
  }
}

WorkflowGraph _promptGraph() {
  return const WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.2'),
        title: 'Prompt',
        description: 'Beschreibung',
        config: PromptNodeConfig(
          instruction: '',
          outputType: PromptOutputType.text,
          choices: ['', ''],
        ),
      ),
    ],
    edges: [],
  );
}
