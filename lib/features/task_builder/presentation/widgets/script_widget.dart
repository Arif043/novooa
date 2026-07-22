import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/agate.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/obsidian.dart';
import 'package:highlight/languages/python.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_file_attachment_section.dart';

class ScriptWidget extends StatefulWidget {
  const ScriptWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<ScriptWidget> createState() => _ScriptWidgetState();
}

class _ScriptWidgetState extends State<ScriptWidget> {
  late final CodeController _controller;

  ScriptNodeConfig get _config {
    return widget.node.config as ScriptNodeConfig;
  }

  @override
  void initState() {
    super.initState();
    _controller = CodeController(text: _config.script, language: python, );  
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
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Script', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          CodeTheme(
            data: CodeThemeData(
              styles: Theme.of(context).brightness == Brightness.dark
                  ? atomOneDarkTheme
                  : atomOneLightTheme,
            ),
            child: CodeField(
              controller: _controller,
              minLines: 6,
              maxLines: 12,
              wrap: false,

              gutterStyle: .new(
                showErrors: true,
                showLineNumbers: true,
                showFoldingHandles: true,
                background: Colors.red
              ),
              // textStyle: Theme.of(
              //   context,
              // ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
              onChanged: _updateScript,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          NodeFileAttachmentSection(
            attachments: _config.attachments,
            onAttach: _attachFile,
            onDetach: _detachFile,
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

  void _attachFile(NodeAttachment attachment) {
    context.read<TaskBuilderCubit>().attachNodeFile(
      nodeId: widget.node.id,
      attachment: attachment,
    );
  }

  void _detachFile(String attachmentId) {
    context.read<TaskBuilderCubit>().detachNodeFile(
      nodeId: widget.node.id,
      attachmentId: attachmentId,
    );
  }
}
