import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_predecessor.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

/// Konfigurationsfläche für „Bedingter Ablauf". Branches selbst werden
/// ausschließlich auf der Haupt-Leinwand verbunden/befüllt (dort bereits
/// vollständig rekursiv abgebildet, siehe `WorkflowCanvasLayout`) — dieses
/// Panel zeigt nur noch die Wert-Bedingung.
class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget({super.key, required this.node});

  final WorkflowNode node;

  ConditionalNodeConfig get _config => node.config as ConditionalNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: _isDrivenByDecisionPrompt(context)
          ? _derivedNotice()
          : _whenSection(context),
    );
  }

  /// Ist der direkte Vorgänger ein Prompt mit „Entscheidung" als Ausgabe,
  /// hält `TaskBuilderGraphMutations._syncConditionalSuccessors` dessen
  /// Choices/`valueTemplate` bereits automatisch synchron — die manuelle
  /// „Wenn"-Eingabe wäre hier nur verwirrend/redundant.
  bool _isDrivenByDecisionPrompt(BuildContext context) {
    final state = context.watch<TaskBuilderCubit>().state;
    if (state is! TaskBuilderLoaded) return false;
    final predecessor = directPredecessorOf(state.editingTask.graph, node.id);
    return predecessor?.config is PromptNodeConfig &&
        (predecessor!.config as PromptNodeConfig).outputType ==
            PromptOutputType.decision;
  }

  Widget _derivedNotice() {
    return Text(
      'Die Verzweigungen werden aus dem vorherigen Prompt-Baustein '
      'ermittelt.',
      style: SyscatTheme.taskBody,
    );
  }

  Widget _whenSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wenn', style: SyscatTheme.taskBody),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: _config.valueTemplate,
          decoration: const InputDecoration(
            labelText: 'Wert',
            hintText: '{{baustein.value}}',
          ),
          onChanged: (value) => context
              .read<TaskBuilderCubit>()
              .updateConditionalValue(node.id, value),
        ),
      ],
    );
  }
}
