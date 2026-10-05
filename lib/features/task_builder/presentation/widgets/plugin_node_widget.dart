import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/runtime/plugins_availability.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_registry_cubit.dart';
import 'package:syscat2/features/plugins/presentation/widgets/plugin_field_editor.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

/// Konfiguration eines Plugin-Bausteins: die Felder stammen aus dem Manifest
/// des Plugins, das hier nur rendert. Fehlt das Plugin (nicht installiert, z. B.
/// nach einem Import), bleibt die Aufgabe bearbeitbar; der Baustein wird beim
/// Ausführen übersprungen.
class PluginNodeWidget extends StatelessWidget {
  const PluginNodeWidget({super.key, required this.node});

  final WorkflowNode node;

  PluginNodeConfig get _config => node.config as PluginNodeConfig;

  @override
  Widget build(BuildContext context) {
    final manifests = pluginsAvailable()
        ? context.watch<PluginRegistryCubit>().state
        : const <PluginManifest>[];
    final manifest = manifests
        .where((candidate) => candidate.id == _config.pluginId)
        .firstOrNull;
    final definition = manifest?.primitive(_config.nodeType);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: definition == null
          ? _Missing(config: _config)
          : _Fields(node: node, config: _config, definition: definition),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.config});

  final PluginNodeConfig config;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.extension_off_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Das Plugin „${config.pluginId}“ ist nicht installiert oder kennt '
            'den Baustein „${config.nodeType}“ nicht. Installiere es unter '
            'Einstellungen → Plugins; bis dahin wird dieser Baustein '
            'übersprungen.',
            style: SyscatTheme.taskBody,
          ),
        ),
      ],
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({
    required this.node,
    required this.config,
    required this.definition,
  });

  final WorkflowNode node;
  final PluginNodeConfig config;
  final PluginPrimitiveDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(definition.label, style: SyscatTheme.taskBody),
        if (definition.settings.isNotEmpty)
          const SizedBox(height: AppSpacing.sm),
        for (final field in definition.settings) ...[
          _field(context, field),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _field(BuildContext context, PluginField field) {
    final value = config.settings[field.key] ?? field.defaultValue;
    void update(Object next) => context.read<TaskBuilderCubit>().updatePluginNode(
      node.id,
      (config) => config.withSetting(field.key, next),
    );
    return switch (field.kind) {
      PluginFieldKind.text ||
      PluginFieldKind.multilineText ||
      PluginFieldKind.template => TemplateExpressionTextField(
        value: value is String ? value : '',
        suggestions: TemplateExpressionScope.suggestionsOf(context),
        minLines: field.kind == PluginFieldKind.multilineText ? 3 : 1,
        maxLines: field.kind == PluginFieldKind.multilineText ? 8 : 1,
        decoration: InputDecoration(
          labelText: field.required ? '${field.label} *' : field.label,
          helperText: field.description,
        ),
        onChanged: update,
      ),
      _ => PluginFieldEditor(
        key: ValueKey('${node.id.value}.${field.key}'),
        field: field,
        value: value,
        onChanged: update,
      ),
    };
  }
}
