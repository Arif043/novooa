/// Erkennt die `workflow_input("pfad")`-Aufrufe eines Scripts, damit der
/// Builder prüfen kann, ob die gelesenen Werte vor dem Baustein entstehen.
///
/// Gleiche Regel wie im Executor (`script-workflow-inputs.ts`): nur feste
/// Texte, nichts hinter `#`, Pfade wie in Templates (`rechnung.summe`,
/// `positionen.0`). Jeder Pfad erscheint einmal, in Reihenfolge.
class ScriptWorkflowInputParser {
  const ScriptWorkflowInputParser();

  List<String> call(String script) {
    final paths = <String>[];
    for (final line in script.split('\n')) {
      for (final match in _call.allMatches(line)) {
        if (line.substring(0, match.start).contains('#')) continue;
        final path = match.group(2)!;
        if (_path.hasMatch(path) && !paths.contains(path)) paths.add(path);
      }
    }
    return paths;
  }
}

final _call = RegExp(r'''\bworkflow_input\(\s*(["'])([^"'\n]+)\1\s*\)''');

final _path = RegExp(
  r'^[\p{L}_][\p{L}\p{N}_]*(?:\.(?:[\p{L}_][\p{L}\p{N}_]*|\d+))*$',
  unicode: true,
);
