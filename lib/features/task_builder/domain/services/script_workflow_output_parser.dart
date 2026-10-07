import '../entities/task_execution_result.dart';

/// Erkennt die `workflow_output("name", "typ", wert)`-Aufrufe eines Scripts,
/// damit der Builder dessen Ausgaben schon vor dem Lauf kennt.
///
/// Erkannt werden nur Aufrufe, deren Name und Typ feste Texte sind. Aufrufe in
/// Kommentaren, ungültige Namen und unbekannte Typen werden übersprungen —
/// zur Laufzeit prüft der Script-Dienst ohnehin jeden Aufruf. Kommt ein Name
/// mehrfach vor, gilt der erste.
class ScriptWorkflowOutputParser {
  const ScriptWorkflowOutputParser();

  List<({String name, NodeOutputType type})> call(String script) {
    final fields = <({String name, NodeOutputType type})>[];
    final seen = <String>{};
    for (final line in script.split('\n')) {
      for (final match in _call.allMatches(line)) {
        if (_isCommentedOut(line, match.start)) continue;
        final field = _fieldFrom(match);
        if (field == null || !seen.add(field.name)) continue;
        fields.add(field);
      }
    }
    return fields;
  }

  ({String name, NodeOutputType type})? _fieldFrom(RegExpMatch match) {
    final name = match.group(2)!;
    final type = _types[match.group(4)!];
    if (type == null || name == 'value' || !_identifier.hasMatch(name)) {
      return null;
    }
    return (name: name, type: type);
  }

  bool _isCommentedOut(String line, int callStart) {
    return line.substring(0, callStart).contains('#');
  }
}

final _call = RegExp(
  r'''\bworkflow_output\(\s*(["'])([^"'\n]+)\1\s*,\s*(["'])([^"'\n]+)\3''',
);

/// Wie `str.isidentifier()` in Python: Buchstabe oder _, dann auch Ziffern.
final _identifier = RegExp(r'^[\p{L}_][\p{L}\p{N}_]*$', unicode: true);

const _types = {
  'string': NodeOutputType.string,
  'number': NodeOutputType.number,
  'boolean': NodeOutputType.boolean,
  'datetime': NodeOutputType.datetime,
  'json': NodeOutputType.json,
};
