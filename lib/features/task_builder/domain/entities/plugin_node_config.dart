import 'node_config.dart';
import 'task_execution_result.dart';
import 'workflow_node.dart';

/// Basis für Konfigurationen, die ein Plugin mitbringt. Sie liegt im Ordner des
/// Plugins; der Kern kennt sie nur über diese Klasse und die Registrierung in
/// `PluginNodeModules`.
abstract class PluginNodeConfig extends NodeConfig {
  const PluginNodeConfig();

  /// Name des Bausteins im Backend und im gespeicherten Dokument.
  String get typeId;

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.plugin;

  /// Felder des Bausteins ohne `primitive`; das ergänzt der Mapper.
  Map<String, Object?> toDocument();

  /// Typ von `{{ausgabe}}`.
  NodeOutputType get primaryOutputType => NodeOutputType.string;

  /// Feste Nebenwerte (`{{ausgabe.feld}}`) samt Typ.
  Map<String, NodeOutputType> get secondaryOutputs => const {};
}

typedef PluginNodeConfigFromDocument =
    PluginNodeConfig Function(Map<String, Object?> data);

/// Wie ein gespeicherter Plugin-Baustein wieder zur Konfiguration wird; die
/// Plugins melden sich über `PluginNodeModules.register` an.
class PluginNodeCodecs {
  PluginNodeCodecs._();

  static final Map<String, PluginNodeConfigFromDocument> _byTypeId = {};

  static void register(
    String typeId,
    PluginNodeConfigFromDocument fromDocument,
  ) {
    _byTypeId[typeId] = fromDocument;
  }

  static void unregister(String typeId) => _byTypeId.remove(typeId);

  static bool contains(Object? typeId) => _byTypeId.containsKey(typeId);

  static PluginNodeConfig? fromDocument(
    Object? typeId,
    Map<String, Object?> data,
  ) {
    return _byTypeId[typeId]?.call(data);
  }
}
