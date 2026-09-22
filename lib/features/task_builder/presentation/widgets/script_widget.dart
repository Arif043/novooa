import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/python.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_file_attachment_section.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/python_analyzer.dart';

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
    _controller = CodeController(
      text: _config.script,
      language: python,
      analyzer: PythonAnalyzer(),
    );
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
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Script', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            initialValue: _config.inputTemplate,
            decoration: const InputDecoration(
              labelText: 'Eingabe',
              hintText: '{{baustein.value}}',
            ),
            onChanged: _updateInput,
          ),
          const SizedBox(height: AppSpacing.md),
          CodeTheme(
            data: CodeThemeData(
              styles: Theme.of(context).brightness == Brightness.dark
                  ? atomOneDarkTheme
                  : atomOneLightTheme,
            ),
            child: CodeField(
              controller: _controller,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.secondary,
              ),
              minLines: 6,
              expands: false,
              wrap: false,
              textStyle: GoogleFonts.jetBrainsMono(),
              gutterStyle: GutterStyle(
                margin: 0,
                textStyle: GoogleFonts.jetBrainsMono(
                  color: ColorScheme.of(context).onSecondary,
                ),
                showErrors: true,
                showLineNumbers: true,
                showFoldingHandles: true,
                background: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
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

  void _updateInput(String inputTemplate) {
    context.read<TaskBuilderCubit>().updateScriptInput(
      widget.node.id,
      inputTemplate,
    );
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
