import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class NodeReferenceNameField extends StatelessWidget {
  const NodeReferenceNameField({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final referenceName = node.referenceName.trim();
    if (referenceName.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: 'Referenzname bearbeiten',
      child: InputChip(
        avatar: const Icon(Icons.data_object_outlined, size: AppSpacing.md),
        label: Text('{{${node.referenceName}.*}}'),
        onPressed: () => _showEditor(context),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context) async {
    final controller = TextEditingController(text: node.referenceName);
    final referenceName = await showIosDialog<String>(
      context: context,
      builder: (dialogContext) => _ReferenceNameDialog(controller: controller),
    );
    controller.dispose();
    if (!context.mounted || referenceName == null) return;
    context.read<TaskBuilderCubit>().updateNodeReferenceName(
      node.id,
      referenceName,
    );
  }
}

class _ReferenceNameDialog extends StatelessWidget {
  const _ReferenceNameDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Referenzname'),
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
