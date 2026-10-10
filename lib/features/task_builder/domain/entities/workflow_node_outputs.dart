import '../services/script_workflow_output_parser.dart';
import 'node_config.dart';
import 'plugin_node_config.dart';
import 'workflow_node.dart';
import 'workflow_output_types.dart';

/// Alle Schlüssel, die ein Baustein als benannte [WorkflowOutput]s führt.
///
/// Bausteine mit Feldern (strukturierte Prompt-Ausgabe, Dialogeingabe,
/// Script mit `workflow_output`) führen je Feld einen Schlüssel — den
/// Feldnamen, unter dem der Executor den Wert ablegt; ihr Gesamtwert ist
/// nicht erreichbar. Alle anderen führen den Hauptwert `value` (außer
/// Bausteinen ohne Rückgabewert) und die weiteren Werte aus [outputFieldsOf].
List<String> outputKeysOf(NodeConfig config) {
  if (hasFlatOutputFields(config)) return _fieldKeysOf(config);
  return [
    if (!config.primitive.hasNoOutput) WorkflowOutput.primaryOutputKey,
    ...outputFieldsOf(config),
  ];
}

/// Ob ein neuer Wert standardmäßig auf der Leinwand steht: der Hauptwert und
/// die Felder (wie vor den benannten Werten), nicht aber weitere Werte wie
/// `found`.
bool defaultShowOnCanvas(NodeConfig config, String key) {
  return key == WorkflowOutput.primaryOutputKey || hasFlatOutputFields(config);
}

/// Feldnamen in Reihenfolge, ohne leere und ohne Doppelte.
List<String> _fieldKeysOf(NodeConfig config) {
  final keys = <String>[];
  for (final field in typedFlatOutputFieldsOf(config)) {
    if (!keys.contains(field.name)) keys.add(field.name);
  }
  return keys;
}

/// Ob ein Baustein statt eines Hauptwerts einzelne Felder liefert
/// (strukturierte Prompt-Ausgabe, Dialogeingabe, Script mit
/// `workflow_output`); siehe [outputKeysOf].
bool hasFlatOutputFields(NodeConfig config) {
  if (config is DialogInputNodeConfig) return true;
  if (config is ScriptNodeConfig) {
    return scriptWorkflowOutputsOf(config).isNotEmpty;
  }
  return config is PromptNodeConfig &&
      config.outputType == PromptOutputType.structured;
}

/// Die per `workflow_output(…)` im Code definierten Ausgaben eines Scripts.
/// Ein Script mit solchen Ausgaben liefert Felder statt eines Hauptwerts;
/// sein Text-`output` ist dann nicht mehr adressierbar.
List<TypedOutputField> scriptWorkflowOutputsOf(ScriptNodeConfig config) {
  return const ScriptWorkflowOutputParser()(config.script);
}

/// Technische Schlüssel der **weiteren** Werte eines Bausteins (neben dem
/// Hauptwert `value`) — der Vertrag mit dem Executor im
/// Backend (`docs/node-executor-outputs.md`). Die Namen, unter denen
/// Nutzer:innen die Werte verwenden (`{{Gefunden}}`), stehen nicht hier,
/// sondern je Baustein in `WorkflowNode.outputs`. Einzige Quelle für
/// Panel (`NodeOutputChips`), #-Suche und die Namensvergabe im Cubit.
/// Bausteine mit Feldern ([hasFlatOutputFields]) haben keine weiteren Werte.
List<String> outputFieldsOf(NodeConfig config) {
  return switch (config) {
    ReadChannelEventNodeConfig() => _channelEventFields(config),
    ReadEmailNodeConfig() => _emailFields,
    WriteFileNodeConfig() => _writeFileFields,
    SendChannelMessageNodeConfig() => _sendMessageFields,
    ModelInferenceNodeConfig() => const ['modelId'],
    DocumentLookupNodeConfig() => const ['found', 'record', 'message'],
    SaveDocumentNodeConfig() => const ['created', 'count', 'records'],
    HttpRequestNodeConfig() => const ['status', 'ok', 'headers'],
    PluginNodeConfig() => config.outputFields.keys.toList(growable: false),
    TableFromCollectionNodeConfig() => const ['rowCount'],
    ReadWebhookNodeConfig() => const [
      'method',
      'query',
      'headers',
      'receivedAt',
    ],
    _ => const [],
  };
}

/// Der Nachrichtentext ist der Hauptwert; nur E-Mails haben einen Betreff.
List<String> _channelEventFields(ReadChannelEventNodeConfig config) {
  if (config.kind == ChannelEventKind.email) {
    return const ['sender', 'subject', 'receivedAt'];
  }
  return const ['sender', 'receivedAt'];
}

const _emailFields = ['sender', 'subject', 'message', 'receivedAt'];
const _sendMessageFields = ['recipient', 'channelId', 'providerMessageId'];
const _writeFileFields = [
  'fileId',
  'versionId',
  'displayName',
  'contentType',
  'sizeBytes',
  'folderId',
  'isNewFile',
];
