import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';

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
/// als Nebenoutput zu listen wäre reine Redundanz.
class NodeOutputChips extends StatelessWidget {
  const NodeOutputChips({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final fields = _secondaryFields(node);
    if (fields.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        label: 'Feste Felder: ${fields.join(', ')}',
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final field in fields) _secondaryFieldChip(context, colors, field),
          ],
        ),
      ),
    );
  }

  Widget _secondaryFieldChip(
    BuildContext context,
    ColorScheme colors,
    String field,
  ) {
    final expression = _expressionFor(field);
    return Tooltip(
      message: 'Antippen, um $expression zu kopieren',
      child: ActionChip(
        label: Text(field),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        backgroundColor: SyscatTheme.primaryOrangeLightest,
        side: BorderSide(color: colors.outlineVariant),
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

  /// Feste Nebenoutputs ohne `value` — der primäre Wert ist bereits über
  /// den Ausgabenamen-Chip erreichbar (siehe Klassendoku).
  List<String> _secondaryFields(WorkflowNode node) {
    return _outputNames(node).where((name) => name != 'value').toList();
  }

  /// Flache Felder (strukturierte Prompt-Ausgabe, Dialogeingabe) sind direkt
  /// ohne Knotennamen erreichbar (`{{feld}}`); alle anderen Bausteine hängen
  /// ihre Nebenoutputs unter ihrem Ausgabenamen ein (`{{ausgabename.feld}}`,
  /// siehe `template-expression-resolver.ts`).
  String _expressionFor(String field) {
    if (_hasFlatOutputs(node)) return '{{$field}}';
    final outputName = node.outputName.trim();
    return outputName.isEmpty ? '{{$field}}' : '{{$outputName.$field}}';
  }

  bool _hasFlatOutputs(WorkflowNode node) {
    final config = node.config;
    if (config is DialogInputNodeConfig) return true;
    return config is PromptNodeConfig &&
        config.outputType == PromptOutputType.structured;
  }

  List<String> _outputNames(WorkflowNode node) {
    final config = node.config;
    return switch (config) {
      PromptNodeConfig() => _promptOutputs(config),
      ReadChannelEventNodeConfig() => _eventOutputs(config),
      ReadEmailNodeConfig() => _emailOutputs,
      WriteFileNodeConfig() => _writeFileOutputs,
      SendChannelMessageNodeConfig() => _sendMessageOutputs,
      StringInputNodeConfig() ||
      ScriptNodeConfig() ||
      ConditionalNodeConfig() ||
      IterativeRefinementNodeConfig() ||
      ReadFileNodeConfig() ||
      HumanApprovalNodeConfig() => const ['value'],
      DialogInputNodeConfig() => _dialogInputOutputNames(config),
      MediaInputNodeConfig() => _mediaInputOutputs,
      ModelInferenceNodeConfig() => const ['value', 'modelId'],
      ForEachNodeConfig() => const ['value'],
      DocumentLookupNodeConfig() => const [
        'value',
        'found',
        'record',
        'message',
      ],
      SaveDocumentNodeConfig() => const [
        'value',
        'created',
        'count',
        'records',
      ],
      _ => const [],
    };
  }

  List<String> _promptOutputs(PromptNodeConfig config) {
    return switch (config.outputType) {
      PromptOutputType.text => const ['value'],
      PromptOutputType.decision => const ['value'],
      // Jedes Feld ist ein eigenständiger, flacher Output ohne
      // umschließenden Knotennamen — kein gemeinsamer `value`-Gesamtwert
      // mehr adressierbar (siehe workflow_canvas_layout.dart).
      PromptOutputType.structured => _structuredNames(config.structuredFields),
      PromptOutputType.image => const ['value'],
    };
  }

  List<String> _eventOutputs(ReadChannelEventNodeConfig config) {
    if (config.kind == ChannelEventKind.email) return _emailOutputs;
    return const ['value', 'sender', 'message', 'receivedAt'];
  }

  List<String> _structuredNames(List<StructuredOutputField> fields) {
    return [
      for (final field in fields)
        if (field.name.trim().isNotEmpty) field.name.trim(),
    ];
  }

  // Jedes Feld ist ein eigenständiger, flacher Output ohne umschließenden
  // Knotennamen — kein gemeinsamer `value`-Gesamtwert mehr adressierbar
  // (siehe workflow_canvas_layout.dart).
  List<String> _dialogInputOutputNames(DialogInputNodeConfig config) {
    return [
      for (final field in config.fields)
        if (field.name.trim().isNotEmpty) field.name.trim(),
    ];
  }
}

const _emailOutputs = ['value', 'sender', 'subject', 'message', 'receivedAt'];
const _sendMessageOutputs = [
  'value',
  'recipient',
  'channelId',
  'providerMessageId',
];
const _writeFileOutputs = [
  'value',
  'fileId',
  'versionId',
  'displayName',
  'contentType',
  'sizeBytes',
  'folderId',
  'isNewFile',
];
const _mediaInputOutputs = ['value'];
