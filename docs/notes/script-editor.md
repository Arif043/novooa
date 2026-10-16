# Script-Editor

> Das Panel zeigt nur eine kompakte Code-Vorschau; zum Schreiben öffnet „Vollbild bearbeiten“ denselben Controller im Vollbild-Dialog.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Vorschau: wenige Zeilen, Zeilenumbruch an, wächst moderat bis zum internen
  Scrollen.
- Vollbild: `ScriptCodeEditor` in `Dialog.fullscreen`
  (`showScriptFullscreenEditor`). Beide Ansichten teilen dieselbe
  `CodeController`-Instanz; es gibt keinen separaten Speicherzustand.
- Syntaxprüfung im Web: Tree-sitter mit lokal ausgelieferter
  Python-Wasm-Grammatik markiert Fehler im Gutter. Läuft nur im Browser,
  führt keinen Code aus und ersetzt keine Laufzeitprüfung.
- Der Builder liest `workflow_output`-Aufrufe aus dem Code
  (`ScriptWorkflowOutputParser`).

## Siehe auch

- [Script: Workflow-Ausgabewerte](./script-workflow-output.md)
- [Script-Executor](./script-executor.md)
