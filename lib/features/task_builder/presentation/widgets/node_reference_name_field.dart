import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class NodeReferenceNameField extends StatefulWidget {
  const NodeReferenceNameField({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<NodeReferenceNameField> createState() => _NodeReferenceNameFieldState();
}

class _NodeReferenceNameFieldState extends State<NodeReferenceNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.node.referenceName);
  }

  @override
  void didUpdateWidget(NodeReferenceNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(widget.node.referenceName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.section * 2,
      child: TextField(
        controller: _controller,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        ],
        decoration: const InputDecoration(
          isDense: true,
          prefixText: '{{',
          suffixText: '.*}}',
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        style: Theme.of(context).textTheme.labelMedium,
        onChanged: _updateReferenceName,
      ),
    );
  }

  void _updateReferenceName(String value) {
    context.read<TaskBuilderCubit>().updateNodeReferenceName(
      widget.node.id,
      value,
    );
  }

  void _syncController(String referenceName) {
    if (_controller.text == referenceName) return;
    _controller.value = _controller.value.copyWith(
      text: referenceName,
      selection: TextSelection.collapsed(offset: referenceName.length),
    );
  }
}
