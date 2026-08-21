import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';

class NodeOutputChips extends StatelessWidget {
  const NodeOutputChips({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final outputNames = _outputNames(node);
    if (outputNames.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        label: 'Ausgaben: ${outputNames.join(', ')}',
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final outputName in outputNames)
              Chip(
                avatar: const Icon(Icons.output_outlined, size: AppSpacing.md),
                label: Text(outputName),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
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
      _ => const [],
    };
  }

  List<String> _promptOutputs(PromptNodeConfig config) {
    return switch (config.outputType) {
      PromptOutputType.text => const ['value'],
      PromptOutputType.decision => const ['value'],
      PromptOutputType.structured => [
        'value',
        ..._structuredNames(config.structuredFields),
      ],
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

  List<String> _dialogInputOutputNames(DialogInputNodeConfig config) {
    return [
      'value',
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
