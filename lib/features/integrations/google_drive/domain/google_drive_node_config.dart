import 'package:syscat2/features/task_builder/domain/entities/plugin_node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

import 'google_drive_actions.dart';

/// Konfiguration einer Drive-Aktion. `action` wählt sie aus, `accountId` das
/// verbundene Google-Konto, `params` trägt die Eingaben der Aktion.
class GoogleDriveNodeConfig extends PluginNodeConfig {
  const GoogleDriveNodeConfig({
    required this.action,
    this.accountId = '',
    this.params = const {},
  });

  factory GoogleDriveNodeConfig.fromDocument(Map<String, Object?> data) {
    final params = data['params'];
    return GoogleDriveNodeConfig(
      action: data['action'] as String? ?? '',
      accountId: data['accountId'] as String? ?? '',
      params: params is Map
          ? {
              for (final entry in params.entries)
                entry.key.toString(): entry.value,
            }
          : const {},
    );
  }

  final String action;

  /// Leer, solange kein Konto gewählt ist.
  final String accountId;
  final Map<String, Object?> params;

  @override
  String get typeId => 'googleDrive.$action';

  @override
  String get documentPrimitive => 'googleDrive';

  @override
  Map<String, Object?> toDocument() => {
    'action': action,
    if (accountId.isNotEmpty) 'accountId': accountId,
    'params': params,
  };

  @override
  NodeOutputType get primaryOutputType =>
      GoogleDriveActions.byId(action)?.primaryOutput ?? NodeOutputType.string;

  @override
  Map<String, NodeOutputType> get outputFields =>
      GoogleDriveActions.byId(action)?.outputFields ?? const {};

  String textParam(String key) {
    final value = params[key];
    return value is String ? value : '';
  }

  GoogleDriveNodeConfig copyWith({
    String? accountId,
    Map<String, Object?>? params,
  }) {
    return GoogleDriveNodeConfig(
      action: action,
      accountId: accountId ?? this.accountId,
      params: params ?? this.params,
    );
  }

  /// Setzt eine Eingabe; leere Texte entfallen, damit das Dokument schlank bleibt.
  GoogleDriveNodeConfig withParam(String key, Object? value) {
    final next = Map<String, Object?>.of(params);
    if (value == null || value == '') {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return copyWith(params: next);
  }

  @override
  List<Object?> get props => [action, accountId, params];
}
