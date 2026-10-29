import '../../../activity/domain/entities/task_activity.dart';
import '../../../activity/domain/entities/task_run.dart';
import '../../../task_builder/domain/entities/workflow_graph.dart';
import 'run_graph_placement.dart';

/// Was ein Baustein in diesem Lauf (und der gewählten Runde) erlebt hat.
enum RunNodeState { succeeded, failed, skipped, waiting, notRun }

/// Ein Lauf mit seinem Graphen (Schnappschuss) und allen Node-Aktivitäten,
/// auch innerhalb von Zweigen und Schleifenrunden.
class RunResult {
  RunResult({required this.run, required this.graph, required this.nodes})
    : _placement = graph == null ? null : RunGraphPlacement(graph);

  final TaskRun run;

  /// `null` bei Läufen von vor dem Graph-Schnappschuss.
  final WorkflowGraph? graph;
  final List<TaskActivity> nodes;
  final RunGraphPlacement? _placement;

  /// Bausteine der obersten Ebene in Ausführungsreihenfolge.
  List<TaskActivity> get topLevel =>
      nodes.where((node) => node.parentNodeId == null).toList();

  /// Alle Folgen des Laufs; nur oberste Ebene, weil umschließende Bausteine
  /// die Folgen ihres Teilgraphen schon tragen.
  List<RunEffect> get effects => [for (final node in topLevel) ...node.effects];

  String? loopOf(String nodeId) => _placement?.loopOf(nodeId);

  /// Titel aus dem Graphen; ohne Graph oder unbekannt die ID.
  String titleOf(String nodeId) => _placement?.titleOf(nodeId) ?? nodeId;

  /// Das Ergebnis eines Bausteins in der Runde, die für seine Schleife
  /// gewählt ist (Standard: erste Runde).
  TaskActivity? resultFor(String nodeId, Map<String, int> rounds) {
    final loop = loopOf(nodeId);
    final round = loop == null ? null : rounds[loop] ?? 0;
    return nodes
        .where((node) => node.nodeId == nodeId && node.iteration == round)
        .lastOrNull;
  }

  RunNodeState stateOf(String nodeId, Map<String, int> rounds) {
    final result = resultFor(nodeId, rounds);
    return switch (result?.status) {
      null => RunNodeState.notRun,
      TaskActivityStatus.failed => RunNodeState.failed,
      TaskActivityStatus.skipped => RunNodeState.skipped,
      TaskActivityStatus.waiting => RunNodeState.waiting,
      TaskActivityStatus.succeeded ||
      TaskActivityStatus.started => RunNodeState.succeeded,
    };
  }

  /// Wie viele Runden eine Schleife hatte (auch eine abgebrochene).
  int roundCountOf(String loopNodeId) {
    final rounds = nodes
        .where((node) => node.parentNodeId == loopNodeId)
        .map((node) => node.iteration)
        .whereType<int>();
    return rounds.isEmpty ? 0 : rounds.reduce((a, b) => a > b ? a : b) + 1;
  }
}
