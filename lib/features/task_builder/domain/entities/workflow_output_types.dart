import 'node_config.dart';
import 'task_execution_result.dart';

/// Ein flaches Ausgabefeld (strukturierte Prompt-Ausgabe, Dialogeingabe)
/// samt Werttyp — Name und Typ stammen aus derselben Konfiguration.
typedef TypedOutputField = ({String name, NodeOutputType type});

/// Typ des primären `value`-Outputs eines Bausteins. Spiegelt die Tabelle
/// „Registrierte Executor" in `docs/node-executor-outputs.md`; Bausteine
/// ohne eigenen Eintrag liefern Text.
NodeOutputType primaryOutputTypeOf(NodeConfig config) {
  return switch (config) {
    PromptNodeConfig(outputType: PromptOutputType.image) =>
      NodeOutputType.media,
    MediaInputNodeConfig() => NodeOutputType.media,
    ModelInferenceNodeConfig() => NodeOutputType.json,
    WriteFileNodeConfig() => NodeOutputType.file,
    TableFromCollectionNodeConfig() => NodeOutputType.table,
    _ => NodeOutputType.string,
  };
}

/// Typ eines festen Nebenoutputs — unabhängig vom Baustein, weil gleich
/// benannte Felder in allen Executoren denselben Typ haben.
NodeOutputType secondaryOutputTypeOf(String field) {
  return switch (field) {
    'receivedAt' => NodeOutputType.datetime,
    'found' || 'created' || 'isNewFile' => NodeOutputType.boolean,
    'count' || 'sizeBytes' || 'rowCount' => NodeOutputType.number,
    'record' || 'records' || 'folderId' => NodeOutputType.json,
    _ => NodeOutputType.string,
  };
}

/// Wie `flatOutputFieldsOf`, aber mit dem Werttyp je Feld. Leere Namen
/// werden ausgelassen.
List<TypedOutputField> typedFlatOutputFieldsOf(NodeConfig config) {
  final fields = switch (config) {
    DialogInputNodeConfig() => [
      for (final field in config.fields)
        (name: field.name.trim(), type: _dialogFieldType(field.type)),
    ],
    PromptNodeConfig(outputType: PromptOutputType.structured) => [
      for (final field in config.structuredFields)
        (name: field.name.trim(), type: _structuredFieldType(field.type)),
    ],
    _ => const <TypedOutputField>[],
  };
  return [
    for (final field in fields)
      if (field.name.isNotEmpty) field,
  ];
}

NodeOutputType _dialogFieldType(DialogInputFieldType type) {
  return switch (type) {
    DialogInputFieldType.number ||
    DialogInputFieldType.integer ||
    DialogInputFieldType.decimal => NodeOutputType.number,
    DialogInputFieldType.boolean => NodeOutputType.boolean,
    _ => NodeOutputType.string,
  };
}

NodeOutputType _structuredFieldType(StructuredFieldType type) {
  return switch (type) {
    StructuredFieldType.string => NodeOutputType.string,
    StructuredFieldType.number => NodeOutputType.number,
    StructuredFieldType.boolean => NodeOutputType.boolean,
  };
}
