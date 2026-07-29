import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/employee_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/knowledge_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

class _InMemoryTaskRepository implements TaskRepository {
  _InMemoryTaskRepository(this.savedTask);

  Task savedTask;

  @override
  Stream<List<Task>> watchTasks() => Stream.value([savedTask]);

  @override
  Future<void> saveTask(Task task) async {
    savedTask = task;
  }

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    return const Error(
      TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
    );
  }
}

Future<void> _closeAndExpectSaved(
  TaskBuilderCubit cubit,
  _InMemoryTaskRepository repository,
  Task task,
) async {
  await cubit.close();
  expect(repository.savedTask, task);
}

void main() {
  test('addNodeToBranch fuegt einen Node in den Branch-Graph ein', () async {
    final repository = _InMemoryTaskRepository(_taskWithConditionalNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.addNodeToBranch(
      conditionalNodeId: const NodeId('node.1'),
      branchId: 'branch.yes',
      primitive: WorkflowPrimitive.prompt,
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as ConditionalNodeConfig;
    final branch = config.branches.first;

    expect(branch.graph.nodes, hasLength(1));
    expect(branch.graph.nodes.first.config, isA<PromptNodeConfig>());
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('addNodeToBranch findet Conditional-Nodes in Branch-Graphs', () async {
    final repository = _InMemoryTaskRepository(
      _taskWithNestedConditionalNode(),
    );
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.addNodeToBranch(
      conditionalNodeId: const NodeId('node.2'),
      branchId: 'branch.nested',
      primitive: WorkflowPrimitive.prompt,
    );

    final state = cubit.state as TaskBuilderLoaded;
    final rootConfig =
        state.editingTask.nodes.first.config as ConditionalNodeConfig;
    final nestedNode = rootConfig.branches.first.graph.nodes.first;
    final nestedConfig = nestedNode.config as ConditionalNodeConfig;
    final nestedBranch = nestedConfig.branches.first;

    expect(nestedBranch.graph.nodes, hasLength(1));
    expect(nestedBranch.graph.nodes.first.config, isA<PromptNodeConfig>());

    await cubit.close();
  });

  test(
    'updatePromptOutputType aktualisiert Prompt-Nodes in Branch-Graphs',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.updatePromptOutputType(
        const NodeId('node.2'),
        PromptOutputType.decision,
      );

      final state = cubit.state as TaskBuilderLoaded;
      final rootConfig =
          state.editingTask.nodes.first.config as ConditionalNodeConfig;
      final prompt = rootConfig.branches.first.graph.nodes.first;
      final promptConfig = prompt.config as PromptNodeConfig;

      expect(promptConfig.outputType, PromptOutputType.decision);
      expect(promptConfig.choices, ['', '']);

      await cubit.close();
    },
  );

  test('removeNode entfernt Nodes aus Branch-Graphs', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.removeNode(const NodeId('node.2'));

    final state = cubit.state as TaskBuilderLoaded;
    final rootConfig =
        state.editingTask.nodes.first.config as ConditionalNodeConfig;
    final branch = rootConfig.branches.first;

    expect(branch.graph.nodes, isEmpty);
    expect(branch.graph.edges, isEmpty);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateNodeReferenceName normalisiert Referenznamen', () async {
    final repository = _InMemoryTaskRepository(_taskWithTwoPromptNodes());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateNodeReferenceName(const NodeId('node.1'), '1 email!');

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.first.referenceName, 'n1email');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateNodeReferenceName macht doppelte Referenzen eindeutig', () async {
    final repository = _InMemoryTaskRepository(_taskWithTwoPromptNodes());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateNodeReferenceName(const NodeId('node.2'), 'prompt1');

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.last.referenceName, 'prompt1_2');

    await cubit.close();
  });

  test('swapNodes tauscht zwei Bausteine in der Reihenfolge', () async {
    final repository = _InMemoryTaskRepository(_taskWithTwoPromptNodes());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.swapNodes(const NodeId('node.1'), const NodeId('node.2'));

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.map((node) => node.id.value), [
      'node.2',
      'node.1',
    ]);
    expect(state.editingTask.edges.single.from, const NodeId('node.2'));
    expect(state.editingTask.edges.single.to, const NodeId('node.1'));
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test(
    'addNode verwendet nach einem Löschen keine bereits belegte ID',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithThreePromptNodes());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.removeNode(const NodeId('node.1'));
      await cubit.addNodeToMainGraph(WorkflowPrimitive.script);

      final state = cubit.state as TaskBuilderLoaded;
      final nodeIds = state.editingTask.nodes.map((node) => node.id.value);
      expect(nodeIds.toSet(), hasLength(nodeIds.length));
      await _closeAndExpectSaved(cubit, repository, state.editingTask);
    },
  );

  test(
    'attachNodeFile speichert Storage-Dateiversion am Prompt-Node',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.attachNodeFile(
        nodeId: const NodeId('node.2'),
        attachment: _attachment,
      );

      var promptConfig = _branchPromptConfig(cubit);
      expect(promptConfig.attachments, [_attachment]);

      await cubit.detachNodeFile(
        nodeId: const NodeId('node.2'),
        attachmentId: _attachment.id,
      );

      final state = cubit.state as TaskBuilderLoaded;
      promptConfig = _branchPromptConfig(cubit);

      expect(promptConfig.attachments, isEmpty);
      await _closeAndExpectSaved(cubit, repository, state.editingTask);
    },
  );

  test(
    'attachNodeFile speichert Storage-Dateiversion am Script-Node',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithScriptNode());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.attachNodeFile(
        nodeId: const NodeId('node.script'),
        attachment: _attachment,
      );

      final state = cubit.state as TaskBuilderLoaded;
      final config = state.editingTask.nodes.first.config as ScriptNodeConfig;

      expect(config.attachments, [_attachment]);
      await _closeAndExpectSaved(cubit, repository, state.editingTask);
    },
  );

  test(
    'load überschreibt keine entfernten Anhaenge mit Navigation-Kopien',
    () async {
      final staleTask = _taskWithScriptNodeWithAttachment();
      final repository = _InMemoryTaskRepository(staleTask);
      final firstCubit = TaskBuilderCubit(repository: repository);

      await firstCubit.load(staleTask);
      await firstCubit.detachNodeFile(
        nodeId: const NodeId('node.script'),
        attachmentId: _attachment.id,
      );
      await firstCubit.close();

      final reopenedCubit = TaskBuilderCubit(repository: repository);
      await reopenedCubit.load(staleTask);

      final state = reopenedCubit.state as TaskBuilderLoaded;
      final config = state.editingTask.nodes.first.config as ScriptNodeConfig;
      expect(config.attachments, isEmpty);
      await reopenedCubit.close();
    },
  );

  test('attachNodeKnowledge speichert Wissensnotiz am Prompt-Node', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.attachNodeKnowledge(
      nodeId: const NodeId('node.2'),
      attachment: _knowledgeAttachment,
    );

    var promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.knowledgeAttachments, [_knowledgeAttachment]);

    await cubit.detachNodeKnowledge(
      nodeId: const NodeId('node.2'),
      attachmentId: _knowledgeAttachment.id,
    );

    final state = cubit.state as TaskBuilderLoaded;
    promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.knowledgeAttachments, isEmpty);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('attachNodeSkill haengt und loest Fähigkeit am Prompt-Node', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.attachNodeSkill(
      nodeId: const NodeId('node.2'),
      attachment: _skillAttachment,
    );

    var promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.skillAttachments, [_skillAttachment]);

    await cubit.attachNodeSkill(
      nodeId: const NodeId('node.2'),
      attachment: _skillAttachment,
    );
    promptConfig = _branchPromptConfig(cubit);
    expect(
      promptConfig.skillAttachments,
      hasLength(1),
      reason: 'gleicher Skill darf nicht doppelt angehängt werden',
    );

    await cubit.detachNodeSkill(
      nodeId: const NodeId('node.2'),
      attachmentId: _skillAttachment.id,
    );

    final state = cubit.state as TaskBuilderLoaded;
    promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.skillAttachments, isEmpty);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('assignNodeEmployee weist einen Mitarbeiter zu und wieder ab', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.assignNodeEmployee(
      nodeId: const NodeId('node.2'),
      attachment: _employeeAttachment,
    );

    var promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.employee, _employeeAttachment);

    await cubit.unassignNodeEmployee(nodeId: const NodeId('node.2'));

    final state = cubit.state as TaskBuilderLoaded;
    promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.employee, isNull);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateScript speichert Script-Code am Script-Node', () async {
    final repository = _InMemoryTaskRepository(_taskWithScriptNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateScript(const NodeId('node.script'), 'output = input');

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as ScriptNodeConfig;

    expect(config.script, 'output = input');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateHumanApproval speichert Freigabe-Anweisung', () async {
    final repository = _InMemoryTaskRepository(_taskWithApprovalNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateHumanApproval(
      const NodeId('node.approval'),
      (config) => config.copyWith(instruction: 'Bitte prüfen.'),
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as HumanApprovalNodeConfig;

    expect(config.instruction, 'Bitte prüfen.');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateWriteFile speichert Dateiname und Inhaltstyp', () async {
    final repository = _InMemoryTaskRepository(_taskWithWriteFileNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateWriteFileName(const NodeId('node.file'), 'bericht.md');
    await cubit.updateWriteFileContentType(
      const NodeId('node.file'),
      'text/markdown',
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as WriteFileNodeConfig;

    expect(config.fileName, 'bericht.md');
    expect(config.contentType, 'text/markdown');
    expect(config.fileId, isNull);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('selectExistingWriteFile speichert bestehende Datei als Ziel', () async {
    final repository = _InMemoryTaskRepository(_taskWithWriteFileNode());
    final cubit = TaskBuilderCubit(repository: repository);
    final attachment = _attachment.copyWith(id: 'file.1:version.2');

    await cubit.load(repository.savedTask);
    await cubit.selectExistingWriteFile(const NodeId('node.file'), attachment);

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as WriteFileNodeConfig;

    expect(config.fileName, attachment.displayName);
    expect(config.contentType, attachment.contentType);
    expect(config.fileId, 'file.1');

    await cubit.close();
  });

  test('selectNewWriteFile speichert neue Datei ohne Datei-ID', () async {
    final repository = _InMemoryTaskRepository(_taskWithWriteFileNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.selectNewWriteFile(
      nodeId: const NodeId('node.file'),
      fileName: 'report.md',
      contentType: '',
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as WriteFileNodeConfig;

    expect(config.fileName, 'report.md');
    expect(config.contentType, 'text/plain');
    expect(config.fileId, isNull);

    await cubit.close();
  });

  test('selectReadFile speichert ausgewaehlte Datei-Version', () async {
    final repository = _InMemoryTaskRepository(_taskWithReadFileNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.selectReadFile(const NodeId('node.read'), _attachment);

    var state = cubit.state as TaskBuilderLoaded;
    var config = state.editingTask.nodes.first.config as ReadFileNodeConfig;
    expect(config.file, _attachment);

    await cubit.clearReadFile(const NodeId('node.read'));

    state = cubit.state as TaskBuilderLoaded;
    config = state.editingTask.nodes.first.config as ReadFileNodeConfig;
    expect(config.file, isNull);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });
}

const _attachment = NodeAttachment(
  id: 'file.briefing.v1',
  storagePath: 'users/u1/uploads/briefing.md',
  generation: '1',
  displayName: 'briefing.md',
  contentType: 'text/markdown',
  sizeBytes: 12000,
);

const _knowledgeAttachment = KnowledgeAttachment(
  knowledgeBaseId: 'default',
  noteId: 'note.1',
  title: 'Index',
  path: 'index.md',
);

const _skillAttachment = SkillAttachment(
  skillId: 'skill.1',
  title: 'E-Mails freundlich beantworten',
  description: 'Nutze diese Fähigkeit für Kundenmails.',
  storagePath: 'teams/team.1/skills/skill.1/SKILL.md',
);

const _employeeAttachment = EmployeeAttachment(
  employeeId: 'employee.1',
  name: 'Rezeption',
  role: 'Du bist die Rezeption von novooa.',
  promptTemplate: '{{instruction}}',
  defaultSkills: [_skillAttachment],
);

Task _taskWithConditionalNode() {
  return _taskWithRootBranch(
    id: 'task.1',
    branchId: 'branch.yes',
    branchLabel: 'Ja',
    branchGraph: const WorkflowGraph(nodes: [], edges: []),
  );
}

PromptNodeConfig _branchPromptConfig(TaskBuilderCubit cubit) {
  final state = cubit.state as TaskBuilderLoaded;
  final rootConfig =
      state.editingTask.nodes.first.config as ConditionalNodeConfig;
  return rootConfig.branches.first.graph.nodes.first.config as PromptNodeConfig;
}

Task _taskWithNestedConditionalNode() {
  return _taskWithRootBranch(
    id: 'task.2',
    branchGraph: const WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.2'),
          title: 'Verzweigung',
          description: 'Beschreibung',
          config: ConditionalNodeConfig(
            branches: [
              ConditionalBranch(
                id: 'branch.nested',
                label: 'Nested',
                graph: WorkflowGraph(nodes: [], edges: []),
              ),
            ],
          ),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithBranchPrompt() {
  return _taskWithRootBranch(
    id: 'task.3',
    branchGraph: const WorkflowGraph(
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
    ),
  );
}

Task _taskWithScriptNode() {
  return const Task(
    id: 'task.script',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.script'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.script'),
          title: 'Script',
          description: 'Beschreibung',
          config: ScriptNodeConfig(script: 'output = ""'),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithScriptNodeWithAttachment() {
  final task = _taskWithScriptNode();
  final node = task.nodes.single;
  return task.copyWith(
    graph: task.graph.copyWith(
      nodes: [
        node.copyWith(
          config: ScriptNodeConfig(
            script: (node.config as ScriptNodeConfig).script,
            attachments: const [_attachment],
          ),
        ),
      ],
    ),
  );
}

Task _taskWithTwoPromptNodes() {
  return const Task(
    id: 'task.references',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.1'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.1'),
          title: 'Prompt',
          description: 'Beschreibung',
          referenceName: 'prompt1',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.text,
            choices: ['', ''],
          ),
        ),
        WorkflowNode(
          id: NodeId('node.2'),
          title: 'Prompt',
          description: 'Beschreibung',
          referenceName: 'prompt2',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.text,
            choices: ['', ''],
          ),
        ),
      ],
      edges: [WorkflowEdge(from: NodeId('node.1'), to: NodeId('node.2'))],
    ),
  );
}

Task _taskWithThreePromptNodes() {
  final task = _taskWithTwoPromptNodes();
  return task.copyWith(
    graph: task.graph.copyWith(
      nodes: [
        ...task.nodes,
        const WorkflowNode(
          id: NodeId('node.3'),
          title: 'Prompt',
          description: 'Beschreibung',
          referenceName: 'prompt3',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.text,
            choices: ['', ''],
          ),
        ),
      ],
      edges: [
        ...task.edges,
        const WorkflowEdge(from: NodeId('node.2'), to: NodeId('node.3')),
      ],
    ),
  );
}

Task _taskWithApprovalNode() {
  return const Task(
    id: 'task.approval',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.approval'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.approval'),
          title: 'Freigabe',
          description: 'Beschreibung',
          config: HumanApprovalNodeConfig(instruction: 'Prüfe das Ergebnis.'),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithWriteFileNode() {
  return const Task(
    id: 'task.file',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.file'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.file'),
          title: 'Datei schreiben',
          description: 'Beschreibung',
          config: WriteFileNodeConfig(
            fileName: 'ausgabe.txt',
            contentType: 'text/plain',
          ),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithReadFileNode() {
  return const Task(
    id: 'task.read',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.read'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.read'),
          title: 'Datei lesen',
          description: 'Beschreibung',
          config: ReadFileNodeConfig(),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithRootBranch({
  required String id,
  required WorkflowGraph branchGraph,
  String branchId = 'branch.root',
  String branchLabel = 'Root',
}) {
  return Task(
    id: id,
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: const NodeId('node.1'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: const NodeId('node.1'),
          title: 'Verzweigung',
          description: 'Beschreibung',
          config: ConditionalNodeConfig(
            branches: [
              ConditionalBranch(
                id: branchId,
                label: branchLabel,
                graph: branchGraph,
              ),
            ],
          ),
        ),
      ],
      edges: [],
    ),
  );
}
