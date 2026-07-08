import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

class _InMemoryTaskRepository implements TaskRepository {
  _InMemoryTaskRepository(this.savedTask);

  Task savedTask;

  @override
  Future<List<Task>> loadTasks() async => [savedTask];

  @override
  Future<void> saveTask(Task task) async {
    savedTask = task;
  }

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    return const Error(
      TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
    );
  }
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
    expect(repository.savedTask, state.editingTask);

    await cubit.close();
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

  test('attachPromptFile speichert Storage-Dateiversion am Prompt', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.attachPromptFile(
      nodeId: const NodeId('node.2'),
      attachment: _attachment,
    );

    var promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.attachments, [_attachment]);

    await cubit.detachPromptFile(
      nodeId: const NodeId('node.2'),
      attachmentId: _attachment.id,
    );

    final state = cubit.state as TaskBuilderLoaded;
    promptConfig = _branchPromptConfig(cubit);

    expect(promptConfig.attachments, isEmpty);
    expect(repository.savedTask, state.editingTask);

    await cubit.close();
  });
}

const _attachment = PromptAttachment(
  id: 'file.briefing.v1',
  storagePath: 'users/u1/uploads/briefing.md',
  generation: '1',
  displayName: 'briefing.md',
  contentType: 'text/markdown',
  sizeBytes: 12000,
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
