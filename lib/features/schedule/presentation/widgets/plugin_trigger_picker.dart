import 'package:flutter/material.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:syscat2/features/plugins/presentation/widgets/plugin_field_editor.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';

/// Ein Trigger eines installierten Plugins samt seinem Plugin.
typedef PluginTriggerOption = ({
  PluginManifest plugin,
  PluginTriggerDefinition trigger,
});

List<PluginTriggerOption> pluginTriggerOptions(
  List<PluginManifest> manifests,
) => [
  for (final plugin in manifests)
    for (final trigger in plugin.triggers) (plugin: plugin, trigger: trigger),
];

String pluginTriggerLabel(PluginTriggerOption option) =>
    '${option.plugin.name} · ${option.trigger.label}';

/// Wählt den Trigger eines Plugins und rendert dessen Einstellungen aus dem
/// Manifest.
class PluginTriggerPicker extends StatelessWidget {
  const PluginTriggerPicker({
    super.key,
    required this.options,
    required this.selection,
    required this.onChanged,
  });

  final List<PluginTriggerOption> options;
  final PluginTriggerSelection? selection;
  final ValueChanged<PluginTriggerSelection> onChanged;

  PluginTriggerOption? get _selected {
    final current = selection;
    if (current == null) return null;
    for (final option in options) {
      if (option.plugin.id == current.pluginId &&
          option.trigger.type == current.type) {
        return option;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<PluginTriggerOption>(
          isExpanded: true,
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Plugin-Ereignis'),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option,
                child: Text(
                  pluginTriggerLabel(option),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (option) {
            if (option == null) return;
            onChanged(
              PluginTriggerSelection(
                pluginId: option.plugin.id,
                type: option.trigger.type,
                label: pluginTriggerLabel(option),
                settings: {
                  for (final field in option.trigger.settings)
                    if (field.defaultValue != null)
                      field.key: field.defaultValue!,
                },
              ),
            );
          },
        ),
        if (selected != null) ...[
          if (selected.trigger.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              selected.trigger.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final field in selected.trigger.settings)
            PluginFieldEditor(
              key: ValueKey(
                '${selected.plugin.id}.${selected.trigger.type}.${field.key}',
              ),
              field: field,
              value: selection!.settings[field.key],
              onChanged: (value) =>
                  onChanged(selection!.withSetting(field.key, value)),
            ),
        ],
      ],
    );
  }
}
