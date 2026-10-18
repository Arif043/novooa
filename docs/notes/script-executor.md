# Script-Executor

> Der Script-Baustein führt Python aus; Werte für Nachfolger entstehen ausschließlich über `workflow_output`.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Es gibt weder `input` noch `output`. Werte vorheriger Bausteine liest das
  Script mit `workflow_input("name")`; `{{…}}` im Code wird nicht ersetzt.
- Ohne `workflow_output`-Aufruf hat der Baustein keine Werte.
- Ein neuer Baustein startet mit einem auskommentierten Beispiel
  (`# workflow_output("name", "string", wert)`, sprachabhängig über
  `NodeTextDefaults.scriptStarter`).
- Variablen eines Scripts bleiben in diesem Script; der Lauf sammelt keine
  Variablen und gibt keinen automatischen Kontext an Prompts.
- Cloud (eingebetteter Python-Pfad): 5 Sekunden, 10 KB Output. Standalone:
  siehe [Script-Dienst: Ausführung und Grenzen](./script-dienst-ausfuehrung.md).
- Port `ScriptExecutor`; `createScriptNodeExecutor` (Domain) gibt nur
  aufgelöste Werte weiter. `createPythonScriptExecutor` ist die
  Subprocess-Runtime der Cloud; die Registry bindet Runtime, temporären
  Workspace und das Protokollieren der Ausgabe.

## Siehe auch

- [Script: Workflow-Ausgabewerte](./script-workflow-output.md)
- [Script: Workflow-Eingabewerte](./script-workflow-input.md)
- [Script-Dienst: Schnittstelle](./script-dienst-schnittstelle.md)
- [Script-Editor](./script-editor.md)
