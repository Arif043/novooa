# Script-Executor

> Der Script-Baustein führt Python aus; Werte für Nachfolger entstehen ausschließlich über `workflow_output`.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Es gibt weder `input` noch `output`. Werte vorheriger Bausteine stehen als
  `{{name}}` im Code; vor dem Lauf wird Text roh, alles andere als JSON
  eingesetzt (`"""{{betreff}}"""`, `json.loads('''{{rechnung}}''')`).
- Ohne `workflow_output`-Aufruf hat der Baustein keine Werte.
- Ein neuer Baustein startet mit einem auskommentierten Beispiel
  (`# workflow_output("name", "string", wert)`, sprachabhängig über
  `NodeTextDefaults.scriptStarter`).
- Script-Variablen bleiben im selben Run erhalten und stehen späteren
  Scripts zur Verfügung.
- Cloud (eingebetteter Python-Pfad): 5 Sekunden, 10 KB Output. Standalone:
  siehe [Script-Dienst: Ausführung und Grenzen](./script-dienst-ausfuehrung.md).
- Port `ScriptExecutor`; `createScriptNodeExecutor` (Domain) gibt nur
  aufgelöste Werte weiter. `createPythonScriptExecutor` ist die
  Subprocess-Runtime der Cloud; die Registry bindet Runtime, temporären
  Workspace und das Protokollieren der Ausgabe.

## Siehe auch

- [Script: Workflow-Ausgabewerte](./script-workflow-output.md)
- [Script-Dienst: Schnittstelle](./script-dienst-schnittstelle.md)
- [Script-Editor](./script-editor.md)
