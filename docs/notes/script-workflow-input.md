# Script: Workflow-Eingabewerte

> `workflow_input("pfad")` liest im Script einen Workflow-Wert typisiert — der einzige Weg, wie Werte in ein Script kommen.

Gehört zu: [Aufgabe](../index/aufgabe.md)

```python
rechnung = workflow_input("rechnung")          # dict
summe = workflow_input("rechnung.summe")       # float
faellig = workflow_input("faellig")            # datetime
betreff = workflow_input("kundenmail.betreff") # str, Anführungszeichen egal

workflow_output("brutto", "number", summe * 1.19)
```

- **Pfade** wie in Templates: Name aus dem flachen Werte-Namensraum, dann
  Felder oder Listenindizes; in Schleifen auch `iteration.value`,
  `iteration.index` und `global.…`.
- **Nur String-Literale** — der Executor liest die Aufrufe vorab
  (`script-workflow-inputs.ts`) und schickt nur diese Werte mit
  (`inputs` neben dem Script). Der Builder nutzt dieselbe Regel
  (`ScriptWorkflowInputParser`).
- **Typen:** Ein ganzer Wert behält seinen Typ, `datetime` kommt als
  `datetime` an. Pfade hinein, Schleifenelement und äußere Werte kommen so,
  wie JSON sie liefert (`str`, `int`/`float`, `bool`, `dict`, `list`; Datei-
  und Medienreferenzen als `dict`).
- **Fehlt ein Wert**, bricht erst der Aufruf ab, mit Zeilenangabe
  (`LookupError: workflow_input("x"): Es gibt keinen Wert „x“.`). Ein Aufruf
  in einem nicht genommenen `if`-Zweig schadet nicht.
- **Kein `{{…}}` im Code:** Das Script geht unverändert in die Ausführung;
  f-Strings und Dict-Literale bleiben, wie sie sind.
- **Keine Variablen:** Was ein Script in Variablen ablegt, bleibt in diesem
  Script. Nachfolger sehen nur `workflow_output`-Werte.
- **Editor:** „Wert einfügen“ im Script-Panel fügt
  `workflow_input("name")` an der Cursorposition ein; liest das Script einen
  Wert, der vor dem Baustein nicht entsteht, warnt ein Hinweis unter dem
  Editor.

## Siehe auch

- [Script: Workflow-Ausgabewerte](./script-workflow-output.md)
- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
- [Script-Executor](./script-executor.md)
