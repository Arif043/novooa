import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/results/domain/entities/run_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

final testRun = TaskRun(
  id: const UniqueId('run-1'),
  taskId: 'task-1',
  taskTitle: 'Rechnungen ablegen',
  status: TaskRunStatus.succeeded,
  updatedAt: DateTime(2026, 10, 28, 10, 0, 4),
  startedAt: DateTime(2026, 10, 28, 10),
  completedAt: DateTime(2026, 10, 28, 10, 0, 4),
  finalOutput: 'Fertig',
);

WorkflowNode textNode(String id) => WorkflowNode(
  id: NodeId(id),
  title: 'Titel $id',
  description: '',
  config: const StringInputNodeConfig(value: ''),
);

/// liste → schleife{ schritt } → weiche{ ja: ja-text | nein: nein-text }
WorkflowGraph testGraph() => WorkflowGraph(
  nodes: [
    textNode('liste'),
    WorkflowNode(
      id: const NodeId('schleife'),
      title: 'Für jedes Element',
      description: '',
      config: ForEachNodeConfig(
        itemsPointer: '',
        graph: WorkflowGraph(nodes: [textNode('schritt')], edges: const []),
      ),
    ),
    WorkflowNode(
      id: const NodeId('weiche'),
      title: 'Weiche',
      description: '',
      config: ConditionalNodeConfig(
        valueTemplate: '',
        branches: [
          ConditionalBranch(
            id: 'ja',
            label: 'Ja',
            graph: WorkflowGraph(nodes: [textNode('ja-text')], edges: const []),
          ),
          ConditionalBranch(
            id: 'nein',
            label: 'Nein',
            graph: WorkflowGraph(
              nodes: [textNode('nein-text')],
              edges: const [],
            ),
          ),
        ],
      ),
    ),
  ],
  edges: const [
    WorkflowEdge(from: NodeId('liste'), to: NodeId('schleife')),
    WorkflowEdge(from: NodeId('schleife'), to: NodeId('weiche')),
  ],
);

TaskActivity activity(
  String nodeId, {
  String? parent,
  int? iteration,
  TaskActivityStatus status = TaskActivityStatus.succeeded,
  Object? value,
  List<RunEffect> effects = const [],
}) => TaskActivity(
  id: UniqueId('$nodeId-${iteration ?? '-'}'),
  runId: const UniqueId('run-1'),
  taskId: 'task-1',
  taskTitle: nodeId,
  target: TaskActivityTarget.node,
  status: status,
  occurredAt: DateTime(2026, 10, 28, 10),
  nodeId: nodeId,
  parentNodeId: parent,
  iteration: iteration,
  outputs: value == null
      ? const {}
      : {
          'value': {'type': 'string', 'value': value},
        },
  effects: effects,
);

const _notification = NotificationSentEffect(
  sourceNodeId: 'schritt',
  title: 'Fertig',
);

RunResult testResult() => RunResult(
  run: testRun,
  graph: testGraph(),
  nodes: [
    activity('liste', value: '3 Rechnungen'),
    activity('schleife', effects: const [_notification, _notification]),
    activity(
      'schritt',
      parent: 'schleife',
      iteration: 0,
      value: 'R-1',
      effects: const [_notification],
    ),
    activity(
      'schritt',
      parent: 'schleife',
      iteration: 1,
      value: 'R-2',
      effects: const [_notification],
    ),
    activity('weiche'),
    activity('ja-text', parent: 'weiche', value: 'Ja-Zweig'),
  ],
);
