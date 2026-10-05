part of 'node_config.dart';

/// Generischer Baustein: Darstellung und Ausführung liefert ein installiertes
/// Plugin. Gespeichert wird nur die Zuordnung ([pluginId], [nodeType]) und die
/// Werte der Felder aus dem Manifest — nie Plugin-Code oder Manifest-Kopien,
/// damit ein Plugin-Update sofort für alle Aufgaben gilt.
class PluginNodeConfig extends NodeConfig {
  const PluginNodeConfig({
    required this.pluginId,
    required this.nodeType,
    this.settings = const {},
  });

  factory PluginNodeConfig.initial() {
    return const PluginNodeConfig(pluginId: '', nodeType: '');
  }

  final String pluginId;
  final String nodeType;

  /// Werte der im Manifest beschriebenen Felder (`String`, `num` oder `bool`);
  /// Text darf Template-Ausdrücke enthalten.
  final Map<String, Object> settings;

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.plugin;

  @override
  List<Object?> get props => [pluginId, nodeType, settings];

  PluginNodeConfig withSetting(String key, Object value) {
    return PluginNodeConfig(
      pluginId: pluginId,
      nodeType: nodeType,
      settings: {...settings, key: value},
    );
  }
}

/// Was die Palette über einen Plugin-Baustein weiß, wenn der Nutzer ihn
/// hinzufügt: Zuordnung, Anzeigetexte und die Standardwerte der Felder.
class PluginNodeSeed {
  const PluginNodeSeed({
    required this.pluginId,
    required this.nodeType,
    required this.title,
    required this.description,
    this.settings = const {},
  });

  final String pluginId;
  final String nodeType;
  final String title;
  final String description;
  final Map<String, Object> settings;

  PluginNodeConfig get config => PluginNodeConfig(
    pluginId: pluginId,
    nodeType: nodeType,
    settings: settings,
  );
}
