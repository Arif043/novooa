import 'package:flutter/widgets.dart';

import '../domain/entities/plugin_node_config.dart';
import '../domain/entities/workflow_node.dart';

/// Alles, was ein Plugin für einen eigenen Baustein im Aufgabenstudio mitbringt.
/// Der Kern kennt dafür nur das Enum-Wert `WorkflowPrimitive.plugin` und diese
/// Registrierung; weitere Verdrahtung (Mapper, Palette, Canvas) entfällt.
class PluginNodeModule {
  const PluginNodeModule({
    required this.typeId,
    String? documentPrimitive,
    required this.title,
    required this.description,
    required this.group,
    required this.icon,
    required this.outputBase,
    required this.initial,
    required this.fromDocument,
    required this.builder,
    this.isAvailable = _always,
  }) : documentPrimitive = documentPrimitive ?? typeId;

  /// Kennung in der Palette und in der Registry, z. B. `shopware.searchOrders`.
  final String typeId;

  /// Name im Backend und im Dokument (`primitive`), z. B. `shopware`. Teilen sich
  /// mehrere Module ein Primitive, ist `fromDocument` bei allen dasselbe.
  final String documentPrimitive;
  final String title;
  final String description;

  /// Gruppe in der Palette, z. B. „Shopware“.
  final String group;
  final IconData icon;

  /// Vorschlag für den Ausgabenamen, z. B. `bestellungen` (es folgt eine Nummer).
  final String outputBase;
  final PluginNodeConfig Function() initial;
  final PluginNodeConfigFromDocument fromDocument;
  final Widget Function(WorkflowNode node) builder;

  /// Ob der Baustein in der Palette erscheint, z. B. je nach Betriebsvariante.
  final bool Function() isAvailable;

  static bool _always() => true;
}

/// Die Plugin-Bausteine der Anwendung. Plugins melden sich beim Start an.
class PluginNodeModules {
  PluginNodeModules._();

  static final Map<String, PluginNodeModule> _byTypeId = {};

  static void register(PluginNodeModule module) {
    _byTypeId[module.typeId] = module;
    PluginNodeCodecs.register(module.documentPrimitive, module.fromDocument);
  }

  static void unregister(String typeId) {
    final module = _byTypeId.remove(typeId);
    if (module == null) return;
    final sharedByOthers = _byTypeId.values.any(
      (other) => other.documentPrimitive == module.documentPrimitive,
    );
    if (!sharedByOthers) PluginNodeCodecs.unregister(module.documentPrimitive);
  }

  static PluginNodeModule? byTypeId(String typeId) => _byTypeId[typeId];

  static List<PluginNodeModule> get all => List.unmodifiable(_byTypeId.values);
}
