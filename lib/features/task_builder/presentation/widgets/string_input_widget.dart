import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class StringInputWidget extends StatefulWidget {
  const StringInputWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<StringInputWidget> createState() => _StringInputWidgetState();
}

class _StringInputWidgetState extends State<StringInputWidget> {
  late final TextEditingController _controller;

  StringInputNodeConfig get _config {
    return widget.node.config as StringInputNodeConfig;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _config.value);
  }

  @override
  void didUpdateWidget(StringInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_config.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Texteingabe', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Text eingeben'),
            onChanged: _updateValue,
          ),
        ],
      ),
    );
  }

  void _syncController(String text) {
    if (_controller.text == text) return;
    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateValue(String value) {
    context.read<TaskBuilderCubit>().updateStringInputValue(
      widget.node.id,
      value,
    );
  }
}
