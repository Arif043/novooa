import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/presentation/widgets/node_activity_values.dart';
import '../../../../activity/presentation/widgets/run_effects/open_effect_file.dart';
import '../../../../activity/presentation/widgets/run_effects/run_effect_list.dart';
import '../../../../activity/presentation/widgets/teamwork_conversation/teamwork_conversation_button.dart';
import '../../../../task_builder/domain/entities/node_config.dart';
import '../../../../task_builder/domain/entities/workflow_graph.dart';
import '../../cubits/run_result_state.dart';
import '../../localization/run_result_texts.dart';

/// Werte, Folgen und Gespräch eines Bausteins in der gewählten Runde.
class RunResultNodeDetails extends StatelessWidget {
  const RunResultNodeDetails({
    super.key,
    required this.state,
    required this.nodeId,
  });

  final RunResultReady state;
  final String nodeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = state.result.resultFor(nodeId, state.rounds);
    final title = _titleOf(nodeId);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          LocaleKeys.results_node_details.tr(namedArgs: {'name': title}),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          RunResultTexts.nodeState(state.result.stateOf(nodeId, state.rounds)),
          style: theme.textTheme.bodySmall,
        ),
        if (result != null) ...[
          NodeActivityValues(activity: result),
          if (result.effects.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            RunEffectList(
              effects: result.effects,
              onOpenFile: (effect) => openEffectFile(context, effect),
            ),
          ],
          if (result.hasConversation) ...[
            const SizedBox(height: AppSpacing.sm),
            TeamworkConversationButton(activity: result),
          ],
        ],
      ],
    );
  }

  String _titleOf(String id) {
    final graph = state.result.graph;
    return graph == null ? id : _titleIn(graph, id) ?? id;
  }

  /// Sucht den Baustein auch in Zweigen und Schleifen.
  String? _titleIn(WorkflowGraph graph, String id) {
    for (final node in graph.nodes) {
      if (node.id.value == id) return node.title;
      final inner = switch (node.config) {
        ForEachNodeConfig(:final graph) => [graph],
        ConditionalNodeConfig(:final branches) => [
          for (final b in branches) b.graph,
        ],
        _ => const <WorkflowGraph>[],
      };
      for (final child in inner) {
        final title = _titleIn(child, id);
        if (title != null) return title;
      }
    }
    return null;
  }
}
