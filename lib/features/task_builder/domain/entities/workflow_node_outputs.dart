import '../services/script_workflow_output_parser.dart';
import 'node_config.dart';
import 'plugin_node_config.dart';
import 'workflow_output_types.dart';

/// Ob ein Baustein seine fachlichen Ausgabewerte flach, ohne umschließenden
/// Ausgabenamen anbietet (strukturierte Prompt-Ausgabe, Dialogeingabe) —
/// jedes Feld hat dort direkt einen eigenen, graph-weit eindeutigen Namen
/// statt eines gemeinsamen `outputName` (siehe `docs/node-executor-outputs.md`).
bool hasFlatOutputFields(NodeConfig config) {
  if (config is DialogInputNodeConfig) return true;
  if (config is ScriptNodeConfig) {
    return scriptWorkflowOutputsOf(config).isNotEmpty;
  }
  return config is PromptNodeConfig &&
      config.outputType == PromptOutputType.structured;
}

/// Die per `workflow_output(…)` im Code definierten Ausgaben eines Scripts.
/// Ein Script mit solchen Ausgaben ist flach wie eine strukturierte
/// Prompt-Ausgabe; sein Text-`output` ist dann nicht mehr adressierbar.
List<TypedOutputField> scriptWorkflowOutputsOf(ScriptNodeConfig config) {
  return const ScriptWorkflowOutputParser()(config.script);
}

/// Die eigenständig benannten Felder eines flachen Bausteins (siehe
/// [hasFlatOutputFields]) — jedes davon ist bereits ein primärer,
/// graph-weiter Name, kein Nebenoutput.
List<String> flatOutputFieldsOf(NodeConfig config) {
  if (config is DialogInputNodeConfig) {
    return _nonEmptyNames(config.fields.map((field) => field.name));
  }
  if (config is PromptNodeConfig &&
      config.outputType == PromptOutputType.structured) {
    return _nonEmptyNames(config.structuredFields.map((field) => field.name));
  }
  if (config is ScriptNodeConfig) {
    return [for (final output in scriptWorkflowOutputsOf(config)) output.name];
  }
  return const [];
}

/// Feste Nebenoutputs eines Bausteins — ohne den primären `value`-Output,
/// der bereits über den Ausgabenamen erreichbar ist (`{{ausgabename}}`).
/// Einzige Quelle für „was liefert dieser Baustein-Typ an Nebenoutputs" —
/// genutzt sowohl von der Detail-Panel-Anzeige (`NodeOutputChips`) als auch
/// von der #-Suche (`templateExpressionSuggestions`), damit beide
/// garantiert dieselbe Antwort geben. Gilt nicht für Bausteine mit
/// [hasFlatOutputFields] — deren Felder sind bereits primäre Outputs, keine
/// Nebenoutputs.
List<String> secondaryOutputFieldsOf(NodeConfig config) {
  return switch (config) {
    ReadChannelEventNodeConfig() => _channelEventFields(config),
    ReadEmailNodeConfig() => _emailFields,
    WriteFileNodeConfig() => _writeFileFields,
    SendChannelMessageNodeConfig() => _sendMessageFields,
    ModelInferenceNodeConfig() => const ['modelId'],
    DocumentLookupNodeConfig() => const ['found', 'record', 'message'],
    SaveDocumentNodeConfig() => const ['created', 'count', 'records'],
    HttpRequestNodeConfig() => const ['status', 'ok', 'headers'],
    PluginNodeConfig() => config.secondaryOutputs.keys.toList(growable: false),
    ReadWebhookNodeConfig() => const [
      'method',
      'query',
      'headers',
      'receivedAt',
    ],
    _ => const [],
  };
}

List<String> _channelEventFields(ReadChannelEventNodeConfig config) {
  if (config.kind == ChannelEventKind.email) return _emailFields;
  return const ['sender', 'message', 'receivedAt'];
}

List<String> _nonEmptyNames(Iterable<String> names) {
  return [
    for (final name in names)
      if (name.trim().isNotEmpty) name.trim(),
  ];
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
