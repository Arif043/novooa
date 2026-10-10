import 'package:syscat2/features/task_builder/domain/entities/plugin_node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

import 'shopware_actions.dart';

/// Konfiguration einer Shopware-Aktion. Alle Aktionen teilen sich diese Klasse;
/// `action` wählt aus, welche, und `params` trägt ihre Eingaben.
class ShopwareNodeConfig extends PluginNodeConfig {
  const ShopwareNodeConfig({
    required this.action,
    this.connectionId = '',
    this.params = const {},
  });

  factory ShopwareNodeConfig.initial(String action) {
    return ShopwareNodeConfig(
      action: action,
      params: Map.of(ShopwareActions.byId(action)?.initialParams ?? const {}),
    );
  }

  factory ShopwareNodeConfig.fromDocument(Map<String, Object?> data) {
    final params = data['params'];
    return ShopwareNodeConfig(
      action: data['action'] as String? ?? '',
      connectionId: data['connectionId'] as String? ?? '',
      params: params is Map
          ? {
              for (final entry in params.entries)
                entry.key.toString(): entry.value,
            }
          : const {},
    );
  }

  final String action;

  /// Leer, solange keine Verbindung gewählt ist.
  final String connectionId;
  final Map<String, Object?> params;

  @override
  String get typeId => 'shopware.$action';

  @override
  String get documentPrimitive => 'shopware';

  @override
  Map<String, Object?> toDocument() => {
    'action': action,
    if (connectionId.isNotEmpty) 'connectionId': connectionId,
    'params': params,
  };

  @override
  NodeOutputType get primaryOutputType =>
      ShopwareActions.byId(action)?.primaryOutput ?? NodeOutputType.string;

  @override
  Map<String, NodeOutputType> get outputFields =>
      ShopwareActions.byId(action)?.outputFields ?? const {};

  ShopwareNodeConfig copyWith({
    String? connectionId,
    Map<String, Object?>? params,
  }) {
    return ShopwareNodeConfig(
      action: action,
      connectionId: connectionId ?? this.connectionId,
      params: params ?? this.params,
    );
  }

  /// Setzt eine Eingabe; leere Texte entfallen, damit das Dokument schlank bleibt.
  ShopwareNodeConfig withParam(String key, Object? value) {
    final next = Map<String, Object?>.of(params);
    if (value == null || value == '') {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return copyWith(params: next);
  }

  @override
  List<Object?> get props => [action, connectionId, params];
}
