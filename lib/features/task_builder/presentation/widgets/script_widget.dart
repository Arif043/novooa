import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_file_attachment_section.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/python_analyzer.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_code_editor.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_fullscreen_editor_dialog.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

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
          _header(context),
          const SizedBox(height: AppSpacing.xs),
          TemplateExpressionTextField(
            value: _config.inputTemplate,
            cursorTarget: TaskBuilderCursorTargets.field(
              widget.node.id,
              NodeFieldKey.inputTemplate,
            ),
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            decoration: const InputDecoration(
              labelText: 'Eingabe',
              hintText: '{{baustein.value}}',
            ),
            onChanged: _updateInput,
          ),
          const SizedBox(height: AppSpacing.md),
          ScriptCodeEditor(
            controller: _controller,
            onChanged: _updateScript,
            minLines: 6,
            maxLines: 20,
          ),
          const SizedBox(height: AppSpacing.xs),
          const _WorkflowOutputHint(),
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

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Script', style: SyscatTheme.taskBody)),
        IconButton(
          tooltip: 'Vollbild bearbeiten',
          onPressed: () => showScriptFullscreenEditor(
            context,
            controller: _controller,
            onChanged: _updateScript,
          ),
          icon: const Icon(Icons.open_in_full),
        ),
      ],
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

/// Kurzreferenz für fachliche Ausgaben; Name und Typ müssen feste Texte sein,
/// damit der Builder sie erkennt.
class _WorkflowOutputHint extends StatelessWidget {
  const _WorkflowOutputHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Fachliche Ausgaben: workflow_output("summe", "number", wert) — '
      'Typen: string, number, boolean, datetime, json. '
      'Nachfolgende Bausteine nutzen sie als {{summe}}.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
