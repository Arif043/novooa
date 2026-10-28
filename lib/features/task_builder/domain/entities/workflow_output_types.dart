import 'node_config.dart';
import 'plugin_node_config.dart';
import 'task_execution_result.dart';
import 'workflow_node_outputs.dart';

/// Ein flaches Ausgabefeld (strukturierte Prompt-Ausgabe, Dialogeingabe)
/// samt Werttyp — Name und Typ stammen aus derselben Konfiguration.
typedef TypedOutputField = ({String name, NodeOutputType type});

/// Typ des primären `value`-Outputs eines Bausteins. Spiegelt die Tabelle
/// „Registrierte Executor" in `docs/notes/executor-outputs.md`; Bausteine
/// ohne eigenen Eintrag liefern Text.
NodeOutputType primaryOutputTypeOf(NodeConfig config) {
  return switch (config) {
    PromptNodeConfig(outputType: PromptOutputType.image) =>
      NodeOutputType.media,
    TextToSpeechNodeConfig() => NodeOutputType.audio,
    SpeechToTextNodeConfig() => NodeOutputType.string,
    ModelInferenceNodeConfig() => NodeOutputType.json,
    WriteFileNodeConfig() => NodeOutputType.file,
    TableFromCollectionNodeConfig() => NodeOutputType.table,
    HttpRequestNodeConfig() => NodeOutputType.json,
    ReadWebhookNodeConfig() => NodeOutputType.json,
    PluginNodeConfig() => config.primaryOutputType,
    _ => NodeOutputType.string,
  };
}

/// Typ des Werts mit [key] eines Bausteins — `value` ist der Hauptwert,
/// bei Bausteinen mit Feldern ist [key] der Feldname.
NodeOutputType outputTypeOf(NodeConfig config, String key) {
  if (hasFlatOutputFields(config)) {
    for (final field in typedFlatOutputFieldsOf(config)) {
      if (field.name == key) return field.type;
    }
  }
  return key == 'value'
      ? primaryOutputTypeOf(config)
      : outputFieldTypeFor(config, key);
}

/// Typ eines weiteren Werts von [config]; Plugins legen ihn selbst fest,
/// alle anderen Bausteine folgen [outputFieldTypeOf].
NodeOutputType outputFieldTypeFor(NodeConfig config, String field) {
  if (config is PluginNodeConfig) {
    return config.outputFields[field] ?? outputFieldTypeOf(field);
  }
  return outputFieldTypeOf(field);
}

/// Typ eines weiteren Werts — unabhängig vom Baustein, weil gleich
/// benannte Schlüssel in allen Executoren denselben Typ haben.
NodeOutputType outputFieldTypeOf(String field) {
  return switch (field) {
    'receivedAt' => NodeOutputType.datetime,
    'found' || 'created' || 'isNewFile' || 'ok' => NodeOutputType.boolean,
    'count' || 'sizeBytes' || 'rowCount' || 'status' => NodeOutputType.number,
    'record' ||
    'records' ||
    'folderId' ||
    'headers' ||
    'query' => NodeOutputType.json,
    _ => NodeOutputType.string,
  };
}

/// Die Felder eines Bausteins mit Feldern samt Werttyp. Leere Namen werden
/// ausgelassen.
List<TypedOutputField> typedFlatOutputFieldsOf(NodeConfig config) {
  final fields = switch (config) {
    DialogInputNodeConfig() => [
      for (final field in config.fields)
        (name: field.name.trim(), type: dialogFieldOutputType(field.type)),
    ],
    PromptNodeConfig(outputType: PromptOutputType.structured) => [
      for (final field in config.structuredFields)
        (name: field.name.trim(), type: structuredFieldOutputType(field.type)),
    ],
    ScriptNodeConfig() => scriptWorkflowOutputsOf(config),
    TeamworkNodeConfig() => [
      for (final field in config.outputFields)
        (name: field.name.trim(), type: structuredFieldOutputType(field.type)),
    ],
    _ => const <TypedOutputField>[],
  };
  return [
    for (final field in fields)
      if (field.name.isNotEmpty) field,
  ];
}

/// Werttyp, den ein Dialogfeld nach dem Absenden liefert.
NodeOutputType dialogFieldOutputType(DialogInputFieldType type) {
  return switch (type) {
    DialogInputFieldType.number ||
    DialogInputFieldType.integer ||
    DialogInputFieldType.decimal => NodeOutputType.number,
    DialogInputFieldType.boolean => NodeOutputType.boolean,
    DialogInputFieldType.image => NodeOutputType.media,
    DialogInputFieldType.date => NodeOutputType.datetime,
    _ => NodeOutputType.string,
  };
}

/// Werttyp, den ein Ergebnisfeld (Prompt, Teamarbeit) liefert.
NodeOutputType structuredFieldOutputType(StructuredFieldType type) {
  return switch (type) {
    StructuredFieldType.string => NodeOutputType.string,
    StructuredFieldType.number => NodeOutputType.number,
    StructuredFieldType.boolean => NodeOutputType.boolean,
    StructuredFieldType.datetime => NodeOutputType.datetime,
    StructuredFieldType.json => NodeOutputType.json,
    StructuredFieldType.file => NodeOutputType.file,
  };
}
