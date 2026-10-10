import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_branches_editor.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/decision_coverage_hint.dart';

/// Konfigurationsfläche für „Bedingter Ablauf". Die Zweig-Subgraphen selbst
/// werden ausschließlich auf der Haupt-Leinwand verbunden/befüllt (siehe
/// `WorkflowCanvasLayout`) — dieses Panel zeigt die Bedingungen der Zweige
/// ([ConditionalBranchesEditor]), immer bearbeitbar. Folgt der Baustein auf
/// einen Entscheidungs-Prompt, weist [DecisionCoverageHint] auf Antworten
/// ohne Zweig hin.
class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecisionCoverageHint(node: node),
          ConditionalBranchesEditor(node: node),
        ],
      ),
    );
  }
}
