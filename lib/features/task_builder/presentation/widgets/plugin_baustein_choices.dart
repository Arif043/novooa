import 'package:syscat2/features/plugins/domain/entities/plugin_manifest.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/entities/workflow_output_types.dart';
import '../../domain/entities/workflow_node.dart';
import 'baustein_palette.dart';

const pluginGroupName = 'Plugins';

/// Die Bausteine installierter Plugins als Palette-Einträge — nach der Gruppe
/// des Manifests, ohne Angabe unter „Plugins“. Reihenfolge wie im Manifest.
Map<String, List<BausteinChoice>> pluginBausteinGroups(
  List<PluginManifest> manifests,
) {
  final groups = <String, List<BausteinChoice>>{};
  for (final manifest in manifests) {
    for (final primitive in manifest.primitives) {
      groups
          .putIfAbsent(primitive.group ?? pluginGroupName, () => [])
          .add(
            BausteinChoice(
              WorkflowPrimitive.plugin,
              plugin: pluginSeedFor(manifest, primitive),
              pluginIcon: primitive.icon,
            ),
          );
    }
  }
  return groups;
}

/// Startwerte eines neuen Plugin-Bausteins: die Standardwerte der Felder.
PluginNodeSeed pluginSeedFor(
  PluginManifest manifest,
  PluginPrimitiveDefinition primitive,
) {
  return PluginNodeSeed(
    pluginId: manifest.id,
    nodeType: primitive.type,
    title: primitive.label,
    description: primitive.description,
    settings: {
      for (final field in primitive.settings)
        if (field.defaultValue != null) field.key: field.defaultValue!,
    },
  );
}

/// Ausgaben eines Plugin-Bausteins außer dem primären `value` — wie bei allen
/// Bausteinen als `{{ausgabename.feld}}` erreichbar. Unbekannt (Plugin fehlt),
/// gibt es keine.
List<TypedOutputField> pluginSecondaryFields(
  List<PluginManifest> manifests,
  PluginNodeConfig config,
) {
  final definition = manifests
      .where((manifest) => manifest.id == config.pluginId)
      .firstOrNull
      ?.primitive(config.nodeType);
  if (definition == null) return const [];
  return [
    for (final output in definition.outputs)
      if (output.name != 'value')
        (name: output.name, type: NodeOutputType.fromName(output.type.name)),
  ];
}
