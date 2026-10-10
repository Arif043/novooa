import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/entities/workflow_node_outputs.dart';
import '../../domain/entities/workflow_output_types.dart';
import '../cubits/task_builder_cubit.dart';
import 'node_output_type_style.dart';
import 'output_canvas_toggle.dart';
import 'output_field_chip.dart';
import 'output_name_dialog.dart';

/// Ein Wert im Panel. Benannte Werte ([output] gesetzt) lassen sich
/// umbenennen und auf die Leinwand holen; flache Felder werden in ihrem
/// eigenen Editor benannt und hier nur kopiert.
typedef _PanelOutput = ({
  String name,
  NodeOutputType type,
  WorkflowOutput? output,
});

/// Zeigt im Panel alle Werte eines Bausteins. Welche davon zusätzlich als
/// Chip auf der Leinwand stehen, entscheidet das Pin-Symbol
/// ([WorkflowOutput.showOnCanvas]).
class NodeOutputChips extends StatelessWidget {
  const NodeOutputChips({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final outputs = _outputs();
    if (outputs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        label: LocaleKeys.ui_fixed_fields_list.tr(
          namedArgs: {'fields': outputs.map(_semanticLabel).join(', ')},
        ),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [for (final output in outputs) _entry(context, output)],
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, _PanelOutput entry) {
    final output = entry.output;
    final chip = OutputFieldChip(
      name: entry.name,
      type: entry.type,
      onRename: output == null ? null : () => _rename(context, output),
    );
    if (output == null) return chip;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip,
        OutputCanvasToggle(
          showOnCanvas: output.showOnCanvas,
          onChanged: (show) =>
              context.read<TaskBuilderCubit>().setOutputOnCanvas(
                nodeId: node.id,
                key: output.key,
                showOnCanvas: show,
              ),
        ),
      ],
    );
  }

  String _semanticLabel(_PanelOutput output) {
    return '${output.name} (${NodeOutputTypeStyle.of(output.type).label})';
  }

  List<_PanelOutput> _outputs() {
    final config = node.config;
    if (hasFlatOutputFields(config)) {
      return [
        for (final field in typedFlatOutputFieldsOf(config))
          (name: field.name, type: field.type, output: null),
      ];
    }
    return [
      for (final output in node.outputs)
        if (output.name.trim().isNotEmpty)
          (
            name: output.name.trim(),
            type: outputTypeOf(config, output.key),
            output: output,
          ),
    ];
  }

  Future<void> _rename(BuildContext context, WorkflowOutput output) async {
    final cubit = context.read<TaskBuilderCubit>();
    final name = await showIosDialog<String>(
      context: context,
      builder: (_) => OutputNameDialog(initialValue: output.name),
    );
    if (name == null) return;
    await cubit.renameOutput(nodeId: node.id, key: output.key, name: name);
  }
}
