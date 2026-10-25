import 'package:flutter/widgets.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/plugin_node_config.dart';
import '../plugin_node_module.dart';
import '../widgets/baustein_palette.dart';
import 'workflow_primitive_labels.dart';

/// Name und Icon der Bausteinart. Plugin-Bausteine teilen sich ein Primitive,
/// deshalb kommen ihre aus dem angemeldeten Modul (z. B. „Produkte suchen“).
extension NodeConfigLabels on NodeConfig {
  String get label => _pluginModule?.title ?? primitive.label;

  IconData get icon => _pluginModule?.icon ?? bausteinIcon(primitive);

  PluginNodeModule? get _pluginModule => switch (this) {
    PluginNodeConfig config => PluginNodeModules.byTypeId(config.typeId),
    _ => null,
  };
}
