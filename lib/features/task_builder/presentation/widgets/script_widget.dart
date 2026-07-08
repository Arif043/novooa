import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class ScriptWidget extends StatefulWidget {
  const ScriptWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<ScriptWidget> createState() => _ScriptWidgetState();
}

class _ScriptWidgetState extends State<ScriptWidget> {
  late final TextEditingController _controller;

  ScriptNodeConfig get _config {
    return widget.node.config as ScriptNodeConfig;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _config.script);
  }

  @override
  void didUpdateWidget(ScriptWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_config.script);
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
          Text('Script', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'output = input.upper()',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: _updateScript,
          ),
        ],
      ),
    );
  }

  void _syncController(String script) {
    if (_controller.text == script) return;
    _controller.value = _controller.value.copyWith(
      text: script,
      selection: TextSelection.collapsed(offset: script.length),
    );
  }

  void _updateScript(String script) {
    context.read<TaskBuilderCubit>().updateScript(widget.node.id, script);
  }
}
