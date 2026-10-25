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
- Grenzen: siehe [Script-Dienst: Ausführung und Grenzen](./script-dienst-ausfuehrung.md).
- Port `ScriptExecutor`; `createScriptNodeExecutor` (Domain) gibt nur
  aufgelöste Werte weiter. Die Registry bindet den Script-Dienst, den
  temporären Workspace und das Protokollieren der Ausgabe; ohne Script-Dienst
  scheitert ein Script verständlich.

## Siehe auch

- [Script: Workflow-Ausgabewerte](./script-workflow-output.md)
- [Script: Workflow-Eingabewerte](./script-workflow-input.md)
- [Script-Dienst: Schnittstelle](./script-dienst-schnittstelle.md)
- [Script-Editor](./script-editor.md)
