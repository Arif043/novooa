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
import 'output_field_chip.dart';
import 'output_name_dialog.dart';

/// Ein Wert im Panel; [fieldKey] ist bei umbenennbaren weiteren Werten der
/// technische Schlüssel (z.B. `found`), bei flachen Feldern `null`.
typedef _PanelOutput = ({String name, NodeOutputType type, String? fieldKey});

/// Zeigt im Panel die Werte eines Bausteins neben seinem Hauptwert —
/// nur hier, nicht auf der Leinwand. Weitere Werte (z.B. `Gefunden`) sind
/// wie der Hauptwert flach erreichbar (`{{Gefunden}}`) und hier
/// umbenennbar; flache Felder (strukturierte Prompt-Ausgabe, Dialogeingabe)
/// werden in ihrem eigenen Editor benannt und hier nur kopiert.
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
          children: [for (final output in outputs) _chip(context, output)],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, _PanelOutput output) {
    final fieldKey = output.fieldKey;
    return OutputFieldChip(
      name: output.name,
      type: output.type,
      onRename: fieldKey == null
          ? null
          : () => _rename(context, fieldKey, output.name),
    );
  }

  String _semanticLabel(_PanelOutput output) {
    return '${output.name} (${NodeOutputTypeStyle.of(output.type).label})';
  }

  /// Werte ohne Namen (Bausteine aus der Zeit vor benannten Werten) fehlen,
  /// weil sie per Template nicht erreichbar sind.
  List<_PanelOutput> _outputs() {
    final config = node.config;
    if (hasFlatOutputFields(config)) {
      return [
        for (final field in typedFlatOutputFieldsOf(config))
          (name: field.name, type: field.type, fieldKey: null),
      ];
    }
    return [
      for (final fieldKey in outputFieldsOf(config))
        if (node.outputFieldNameOf(fieldKey).isNotEmpty)
          (
            name: node.outputFieldNameOf(fieldKey),
            type: outputFieldTypeFor(config, fieldKey),
            fieldKey: fieldKey,
          ),
    ];
  }

  Future<void> _rename(
    BuildContext context,
    String fieldKey,
    String currentName,
  ) async {
    final cubit = context.read<TaskBuilderCubit>();
    final name = await showIosDialog<String>(
      context: context,
      builder: (_) => OutputNameDialog(initialValue: currentName),
    );
    if (name == null) return;
    await cubit.renameOutputField(
      nodeId: node.id,
      fieldKey: fieldKey,
      name: name,
    );
  }
}
