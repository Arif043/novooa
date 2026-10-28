import '../../../../task_builder/domain/entities/workflow_graph.dart';
import '../../../../task_builder/presentation/widgets/workflow_canvas_frame.dart';
import '../../../../task_builder/presentation/widgets/workflow_canvas_layout.dart';

/// Das Layout der Leinwand ohne die Einfügestellen des Editors: Im Ergebnis
/// gibt es nichts anzufügen, die Platzhalter am Ende jedes Strangs fallen weg.
CanvasFrame resultCanvasFrame(
  WorkflowGraph graph, {
  required double textScale,
}) {
  final layout = WorkflowCanvasLayout(graph, textScale: textScale);
  bool isInsertion(String id) => id.startsWith('@append:');
  layout.entries.removeWhere((id, _) => isInsertion(id));
  layout.links.removeWhere(
    (link) => isInsertion(link.to) || isInsertion(link.from),
  );
  layout.rectangles.removeWhere((id, _) => isInsertion(id));
  return CanvasFrame.of(layout);
}
