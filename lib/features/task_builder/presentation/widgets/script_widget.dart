import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
import 'package:syscat2/features/task_builder/presentation/widgets/script_input_warning.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_packages/script_packages_section.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_workflow_input_insertion.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_picker.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';

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
    final suggestions = TemplateExpressionScope.suggestionsOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: AppSpacing.xs),
          ScriptCodeEditor(
            controller: _controller,
            onChanged: _updateScript,
            minLines: 6,
            maxLines: 20,
          ),
          ScriptInputWarning(
            unknownPaths: unknownScriptInputs(_config.script, suggestions),
          ),
          const SizedBox(height: AppSpacing.xs),
          const _WorkflowOutputHint(),
          const SizedBox(height: AppSpacing.md),
          ScriptPackagesSection(
            script: _config.script,
            packages: _config.packages,
            onChanged: (packages) => context
                .read<TaskBuilderCubit>()
                .updateScriptPackages(widget.node.id, packages),
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

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(LocaleKeys.ui_script.tr(), style: SyscatTheme.taskBody),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_insert_workflow_input.tr(),
          onPressed: () => _insertInput(context),
          icon: const Icon(Icons.data_object),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_vollbild_bearbeiten.tr(),
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

  Future<void> _insertInput(BuildContext context) async {
    final suggestion = await pickTemplateExpression(
      context,
      TemplateExpressionScope.suggestionsOf(context),
    );
    if (!mounted || suggestion == null) return;
    final call = workflowInputCallFor(suggestion.expression);
    _controller.value = insertAtSelection(_controller.value, call);
    _updateScript(_controller.text);
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

/// Kurzreferenz für fachliche Ausgaben; Name und Typ müssen feste Texte sein,
/// damit der Builder sie erkennt.
class _WorkflowOutputHint extends StatelessWidget {
  const _WorkflowOutputHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.ui_script_outputs_hint.tr(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
