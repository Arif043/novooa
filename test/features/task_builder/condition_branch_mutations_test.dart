import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

// Deckt `TaskBuilderConditionBranchMutations` ab: addConditionBranch,
// removeConditionBranch, updateBranchCondition — inkl. der automatischen
// Erzeugung/Entfernung des "Sonst"-Branches.
void main() {
  const conditionalId = NodeId('conditional.1');

  test(
    'addConditionBranch erzeugt beim ersten Aufruf einen bedingten Branch '
    'plus automatischen Sonst-Branch',
    () async {
      final cubit = await _cubitFor(_branchFreeTask());

      await cubit.addConditionBranch(conditionalId);

      final config = _configOf(cubit);
      expect(config.branches, hasLength(2));
      expect(config.branches[0].label, 'Bedingung 1');
      expect(config.branches[0].condition, isA<ComparisonCondition>());
      expect(config.branches[1].label, 'Sonst');
      expect(config.branches[1].condition, isNull);
      await cubit.close();
    },
  );

  test(
    'ein zweiter addConditionBranch-Aufruf fügt vor dem bestehenden '
    'Sonst-Branch ein, statt einen weiteren Sonst-Branch zu erzeugen',
    () async {
      final cubit = await _cubitFor(_branchFreeTask());
      await cubit.addConditionBranch(conditionalId);

      await cubit.addConditionBranch(conditionalId);

      final config = _configOf(cubit);
      expect(config.branches, hasLength(3));
      expect(config.branches[0].label, 'Bedingung 1');
      expect(config.branches[1].label, 'Bedingung 2');
      expect(config.branches[2].label, 'Sonst');
      expect(config.branches[2].condition, isNull);
      await cubit.close();
    },
  );

  test(
    'removeConditionBranch entfernt einen bedingten Branch, lässt den '
    'Sonst-Branch aber bestehen, solange ein weiterer bedingter Branch '
    'übrig bleibt',
    () async {
      final cubit = await _cubitFor(_branchFreeTask());
      await cubit.addConditionBranch(conditionalId);
      await cubit.addConditionBranch(conditionalId);
      final firstBranchId = _configOf(cubit).branches[0].id;

      await cubit.removeConditionBranch(conditionalId, firstBranchId);

      final config = _configOf(cubit);
      expect(config.branches, hasLength(2));
      expect(config.branches[0].label, 'Bedingung 2');
      expect(config.branches[1].label, 'Sonst');
      await cubit.close();
    },
  );

  test(
    'removeConditionBranch entfernt auch den Sonst-Branch, wenn der letzte '
    'bedingte Branch entfernt wird — Rückkehr zum branchfreien Zustand',
    () async {
      final cubit = await _cubitFor(_branchFreeTask());
      await cubit.addConditionBranch(conditionalId);
      final onlyBranchId = _configOf(cubit).branches[0].id;

      await cubit.removeConditionBranch(conditionalId, onlyBranchId);

      expect(_configOf(cubit).branches, isEmpty);
      await cubit.close();
    },
  );

  test('removeConditionBranch entfernt den Sonst-Branch selbst nicht', () async {
    final cubit = await _cubitFor(_branchFreeTask());
    await cubit.addConditionBranch(conditionalId);
    final sonstId = _configOf(cubit).branches[1].id;

    await cubit.removeConditionBranch(conditionalId, sonstId);

    expect(_configOf(cubit).branches, hasLength(2));
    await cubit.close();
  });

  test(
    'updateBranchCondition ersetzt den Ausdrucksbaum eines bedingten '
    'Branches atomar',
    () async {
      final cubit = await _cubitFor(_branchFreeTask());
      await cubit.addConditionBranch(conditionalId);
      final branchId = _configOf(cubit).branches[0].id;
      const newCondition = GroupCondition(
        combinator: BooleanCombinator.and,
        children: [
          ComparisonCondition(
            left: '{{x}}',
            operator: ComparisonOperator.greaterThan,
            right: '0',
          ),
          ComparisonCondition(
            left: '{{y}}',
            operator: ComparisonOperator.equals,
            right: 'ja',
          ),
        ],
      );

      await cubit.updateBranchCondition(
        conditionalNodeId: conditionalId,
        branchId: branchId,
        condition: newCondition,
      );

      expect(_configOf(cubit).branches[0].condition, newCondition);
      await cubit.close();
    },
  );

  test(
    'updateBranchCondition lässt den Sonst-Branch unangetastet (er hat '
    'per Definition kein condition-Feld, das ersetzt werden könnte)',
    () async {
      final cubit = await _cubitFor(_branchFreeTask());
      await cubit.addConditionBranch(conditionalId);
      final sonstId = _configOf(cubit).branches[1].id;

      await cubit.updateBranchCondition(
        conditionalNodeId: conditionalId,
        branchId: sonstId,
        condition: const ComparisonCondition(
          left: '{{x}}',
          operator: ComparisonOperator.equals,
          right: '1',
        ),
      );

      expect(_configOf(cubit).branches[1].condition, isNull);
      await cubit.close();
    },
  );
}

Future<TaskBuilderCubit> _cubitFor(Task task) async {
  final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(task));
  await cubit.load(task);
  return cubit;
}

ConditionalNodeConfig _configOf(TaskBuilderCubit cubit) {
  final state = cubit.state as TaskBuilderLoaded;
  return state.editingTask.nodes.single.config as ConditionalNodeConfig;
}

Task _branchFreeTask() {
  const conditionalId = NodeId('conditional.1');
  return const Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: conditionalId,
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: conditionalId,
          title: 'Bedingter Ablauf',
          description: '',
          config: ConditionalNodeConfig(branches: []),
        ),
      ],
      edges: [],
    ),
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
