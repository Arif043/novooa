import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/entities/workflow_node_outputs.dart';
import '../../domain/entities/workflow_output_types.dart';
import 'node_output_type_style.dart';

/// Zeigt die **festen Nebenoutputs** eines Bausteins (z.B. `sender`,
/// `created`) — bewusst anders gestaltet als der editierbare Ausgabename
/// ([NodeOutputNameField]): outlined statt gefüllt, gedämpfte statt
/// Akzentfarbe, kein Stift-Icon. Diese Felder beschreiben feste Argumente
/// des Baustein-Typs, keine vom Nutzer gewählten Namen — Tippen kopiert
/// deshalb nur die fertige Template-Referenz, statt eine Umbenennung
/// anzubieten.
///
/// `value` wird hier nie angezeigt: Der primäre Wert ist bereits über den
/// Ausgabenamen-Chip darüber sichtbar (`{{ausgabename}}`); ihn hier erneut
/// als Nebenoutput zu listen wäre reine Redundanz. Die fachliche Frage
/// „welche Felder hat dieser Baustein-Typ" beantwortet ausschließlich
/// `workflow_node_outputs.dart` (Domain) — dieselbe Quelle, die auch die
/// #-Suche (`templateExpressionSuggestions`) nutzt.
class NodeOutputChips extends StatelessWidget {
  const NodeOutputChips({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final fields = _displayFields();
    if (fields.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        label: 'Feste Felder: ${fields.map(_semanticLabel).join(', ')}',
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final field in fields) _fieldChip(context, colors, field),
          ],
        ),
      ),
    );
  }

  String _semanticLabel(TypedOutputField field) {
    return '${field.name} (${NodeOutputTypeStyle.of(field.type).label})';
  }

  Widget _fieldChip(
    BuildContext context,
    ColorScheme colors,
    TypedOutputField field,
  ) {
    final expression = _expressionFor(field.name);
    final style = NodeOutputTypeStyle.of(field.type);
    return Tooltip(
      message: '${style.label} · Antippen, um $expression zu kopieren',
      child: ActionChip(
        avatar: Icon(style.icon, size: AppSpacing.md, color: style.color),
        label: Text(field.name),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurface,
        ),
        backgroundColor: style.color.withValues(alpha: 0.12),
        side: BorderSide(color: style.color.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
        onPressed: () => _copyExpression(context, expression),
      ),
    );
  }

  Future<void> _copyExpression(BuildContext context, String expression) async {
    await Clipboard.setData(ClipboardData(text: expression));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$expression kopiert.')));
  }

  /// Flache Felder (strukturierte Prompt-Ausgabe, Dialogeingabe) sind schon
  /// primäre Outputs; alle anderen Bausteine zeigen ihre festen
  /// Nebenoutputs (ohne `value`, siehe Klassendoku).
  List<TypedOutputField> _displayFields() {
    final config = node.config;
    if (hasFlatOutputFields(config)) return typedFlatOutputFieldsOf(config);
    return [
      for (final name in secondaryOutputFieldsOf(config))
        (name: name, type: secondaryOutputTypeOf(name)),
    ];
  }

  /// Flache Felder sind direkt ohne Knotennamen erreichbar (`{{feld}}`);
  /// alle anderen Bausteine hängen ihre Nebenoutputs unter ihrem
  /// Ausgabenamen ein (`{{ausgabename.feld}}`, siehe
  /// `template-expression-resolver.ts`).
  String _expressionFor(String field) {
    if (hasFlatOutputFields(node.config)) return '{{$field}}';
    final outputName = node.outputName.trim();
    return outputName.isEmpty ? '{{$field}}' : '{{$outputName.$field}}';
  }
}
