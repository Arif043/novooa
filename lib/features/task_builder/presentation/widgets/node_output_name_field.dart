import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

/// Zeigt und bearbeitet den fachlichen Ausgabenamen eines Bausteins mit
/// genau einem Output — direkt als Template-Ausdruck nutzbar (`{{name}}`).
///
/// Bausteine mit mehreren fachlichen Outputs (strukturierte Prompt-Ausgabe,
/// Dialogeingabe) haben keinen eigenen Ausgabenamen; dort vergibt der Nutzer
/// stattdessen für jedes Feld einen eigenen Namen (siehe die jeweiligen
/// Feld-Editoren), weshalb dieses Widget sich dafür ausblendet.
class NodeOutputNameField extends StatelessWidget {
  const NodeOutputNameField({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    if (_hasIndependentlyNamedOutputs(node.config)) {
      return const SizedBox.shrink();
    }
    final outputName = node.outputName.trim();
    if (outputName.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: 'Ausgabename bearbeiten',
      child: InputChip(
        avatar: const Icon(Icons.data_object_outlined, size: AppSpacing.md),
        label: Text('{{$outputName}}'),
        onPressed: () => _showEditor(context),
      ),
    );
  }

  bool _hasIndependentlyNamedOutputs(NodeConfig config) {
    if (config is DialogInputNodeConfig) return true;
    return config is PromptNodeConfig &&
        config.outputType == PromptOutputType.structured;
  }

  Future<void> _showEditor(BuildContext context) async {
    final controller = TextEditingController(text: node.outputName);
    final outputName = await showIosDialog<String>(
      context: context,
      builder: (dialogContext) => _OutputNameDialog(controller: controller),
    );
    controller.dispose();
    if (!context.mounted || outputName == null) return;
    context.read<TaskBuilderCubit>().updateNodeOutputName(node.id, outputName);
  }
}

class _OutputNameDialog extends StatelessWidget {
  const _OutputNameDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Ausgabename'),
      content: TextField(
        controller: controller,
        autofocus: true,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        ],
        decoration: const InputDecoration(hintText: 'zum_beispiel_bericht'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
