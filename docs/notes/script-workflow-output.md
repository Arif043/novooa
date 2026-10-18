# Script: Workflow-Ausgabewerte

> `workflow_output(name, type, value)` legt einen typisierten Wert an, den Nachfolger flach als `{{name}}` lesen — der einzige Weg zu Werten eines Scripts.

Gehört zu: [Aufgabe](../index/aufgabe.md)

```python
from datetime import datetime, timedelta

summe = sum(p["betrag"] for p in positionen)
workflow_output("summe", "number", summe)
workflow_output("faellig", "datetime", datetime.now() + timedelta(days=14))
workflow_output("rechnung", "json", {"nr": "R-1", "positionen": positionen})
```

- **Typen:** `string`, `number` (endlich, kein `bool`), `boolean`, `datetime`
  (`datetime`/`date` oder ISO-Text, gespeichert als ISO-Text), `json`.
- **Namen:** wie Python-Bezeichner, nicht `value`, je Script nur einmal.
- **Nur String-Literale** für Name und Typ (keine Variablen, keine
  f-Strings) — nur so kennt der Builder die Werte vor dem Lauf.
- **Prüfung:** Der Script-Dienst prüft sofort und bricht mit Zeilenangabe ab
  (`Zeile 3: TypeError: workflow_output("summe"): erwartet number, erhalten
  str.`); der Executor prüft erneut (`script-workflow-outputs.ts`).
- **Builder:** `ScriptWorkflowOutputParser` liest die Aufrufe; jede Ausgabe
  wird ein Wert in `outputs` (Schlüssel = Name im Code), umbenennbar und
  graph-weit eindeutig (`summe`, `summe2`), standardmäßig auf der Leinwand.
- **Cloud:** Der eingebettete Pfad (`scriptPythonSource`) sammelt die
  Aufrufe ohne eigene Prüfung (nur `datetime`/`date` → ISO-Text); dort prüft
  allein der Executor.

## Siehe auch

- [Script-Executor](./script-executor.md)
- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
