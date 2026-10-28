import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../task_builder/domain/entities/node_config.dart';
import '../../../../task_builder/presentation/widgets/workflow_canvas_frame.dart';
import '../../../../task_builder/presentation/widgets/workflow_canvas_layout.dart';
import '../../../../task_builder/presentation/widgets/workflow_edges_painter.dart';
import '../../cubits/run_result_state.dart';
import 'run_result_node_card.dart';
import 'run_result_value_chip.dart';
import 'run_result_values.dart';

/// Kanten mit echten Werten und die Ergebniskarten in Leinwand-Koordinaten.
class RunResultScene extends StatelessWidget {
  const RunResultScene({
    super.key,
    required this.frame,
    required this.state,
    required this.onSelectNode,
    required this.onSelectRound,
  });

  final CanvasFrame frame;
  final RunResultReady state;
  final ValueChanged<String> onSelectNode;
  final void Function(String loopNodeId, int round) onSelectRound;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: frame.size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WorkflowEdgesPainter(
                frame,
                Theme.of(context).colorScheme,
              ),
            ),
          ),
          for (final link in frame.links)
            if (link.link.labels.isNotEmpty && !link.link.isReturn)
              Positioned(
                left: canvasLabelAnchor(link).dx,
                top: canvasLabelAnchor(link).dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _LinkLabels(link: link.link, state: state),
                ),
              ),
          for (final entry in frame.entries)
            Positioned.fromRect(
              rect: frame.rectangles[entry.id]!,
              child: _entryView(entry),
            ),
        ],
      ),
    );
  }

  Widget _entryView(CanvasEntry entry) {
    final node = entry.node;
    if (node == null) return _Junction(label: entry.continuationLabel);
    final id = node.id.value;
    final result = state.result.resultFor(id, state.rounds);
    final roundCount = node.config is ForEachNodeConfig
        ? state.result.roundCountOf(id)
        : 0;
    return RunResultNodeCard(
      node: node,
      state: state.result.stateOf(id, state.rounds),
      preview: RunResultValues.previewOf(result),
      effectCount: result?.effects.length ?? 0,
      selected: state.selectedNodeId == id,
      onTap: () => onSelectNode(id),
      rounds: roundCount == 0
          ? null
          : (
              round: state.roundOf(id),
              count: roundCount,
              onChanged: (round) => onSelectRound(id, round),
            ),
    );
  }
}

class _LinkLabels extends StatelessWidget {
  const _LinkLabels({required this.link, required this.state});

  final CanvasLink link;
  final RunResultReady state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final label in link.labels) ...[
          RunResultValueChip(
            text: _textOf(label),
            isCondition: link.isCondition,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  /// Statt des Ausgabenamens der Wert, den der Baustein geliefert hat.
  String _textOf(CanvasLabel label) {
    final target = label.editTarget;
    if (target is! OutputEditTarget) return label.text;
    final result = state.result.resultFor(target.nodeId.value, state.rounds);
    return RunResultValues.valueOf(result, target.key) ?? label.text;
  }
}

/// Verbindungsstelle nach einem Zweig oder einer Schleife.
class _Junction extends StatelessWidget {
  const _Junction({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = label;
    return Center(
      child: text == null
          ? Icon(
              Icons.circle,
              size: AppSpacing.sm,
              color: theme.colorScheme.outlineVariant,
            )
          : Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}
