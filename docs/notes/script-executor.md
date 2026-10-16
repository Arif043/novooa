# Script-Executor

> Der Script-Baustein führt Python mit der Eingabe aus `inputTemplate` aus; Werte für Nachfolger entstehen nur über `workflow_output`.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- `input` kommt aus dem expliziten Feld `inputTemplate`.
- Eine gesetzte Variable `output` liefert der Executor weiter als `value`;
  der Builder führt dafür keinen Wert, sie ist per Template nicht erreichbar.
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
