import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_activity.dart';
import 'node_output_formatter.dart';

class NodeActivityValues extends StatelessWidget {
  const NodeActivityValues({super.key, required this.activity});

  final TaskActivity activity;

  @override
  Widget build(BuildContext context) {
    final outputs = _outputs;
    if (outputs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final output in outputs) _NodeActivityValue(output: output),
        ],
      ),
    );
  }

  List<NodeOutput> get _outputs {
    return [
      for (final entry in activity.outputs.entries)
        NodeOutput.fromStored(entry.key, entry.value),
      if (_hasText(activity.output))
        NodeOutput(name: 'output', label: 'Ausgabe', value: activity.output),
      if (_hasText(activity.input))
        NodeOutput(name: 'input', label: 'Eingabe', value: activity.input),
      if (_hasText(activity.message))
        NodeOutput(name: 'message', label: 'Hinweis', value: activity.message),
    ];
  }

  bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;
}

class _NodeActivityValue extends StatelessWidget {
  const _NodeActivityValue({required this.output});

  final NodeOutput output;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(output.label, style: textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          _NodeOutputValue(output: output),
        ],
      ),
    );
  }
}

class _NodeOutputValue extends StatelessWidget {
  const _NodeOutputValue({required this.output});

  final NodeOutput output;

  @override
  Widget build(BuildContext context) {
    final value = output.displayValue;
    if (value is Map) return _StructuredMapValue(values: value);
    if (value is List) return _StructuredListValue(values: value);
    return SelectableText(
      NodeOutputFormatter.format(output),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _StructuredMapValue extends StatelessWidget {
  const _StructuredMapValue({required this.values});

  final Map<dynamic, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in values.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SelectableText.rich(
              TextSpan(
                style: textTheme.bodySmall,
                children: [
                  TextSpan(
                    text:
                        '${NodeOutputFormatter.labelFor(entry.key.toString())}: ',
                    style: textTheme.labelSmall,
                  ),
                  TextSpan(text: NodeOutputFormatter.formatValue(entry.value)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StructuredListValue extends StatelessWidget {
  const _StructuredListValue({required this.values});

  final List<dynamic> values;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SelectableText(
              '• ${NodeOutputFormatter.formatValue(value)}',
              style: textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
