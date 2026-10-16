# Script-Ausgabe im Protokoll

> Alles, was ein Script auf stdout und stderr schreibt, erscheint nach dem Lauf im Protokoll und an der Aktivität des Bausteins, auch bei Abbruch.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Der Dienst fängt die echten Dateideskriptoren 1 und 2 in Dateien ab, nicht
nur `sys.stdout`. Damit sind `subprocess`, `os.write(1, …)` und Warnungen
dabei; `python -u` verhindert Pufferreste. Bei Fehlern stehen `printed` und
`stderr` in der `422`-Antwort; der Baustein protokolliert sie vor der
Fehlermeldung (`ScriptExecutionError`).

**Aktivitäten → Protokoll:**

- stdout: Info, Ereignis `script_node.stdout`, „[Script-Log] …“, Festbreite
  auf neutraler Fläche.
- stderr: Fehler, Ereignis `script_node.stderr`, „[Script-Fehlerausgabe] …“,
  Festbreite und rötlich (`LogMessage`). Ohne Fehlerausgabe kein Eintrag.

**Aktivität des Bausteins** (Verlauf → Aufgabe): „Baustein ausgeführt“ zeigt
die Abschnitte „Script-Ausgabe (stdout)“ und „Fehlerausgabe (stderr)“. Das
Ergebnis trägt `console: {stdout, stderr}` (Spalte `activities.console_json`,
`console` in `GET /v1/activities`).

Beide Ausgaben sind auf 256 KB begrenzt („[Ausgabe gekürzt]“) und erscheinen
erst nach Laufende, nicht live. Der Script-Fehler selbst steht als Meldung mit
Zeilenangabe im Lauf und ist keine stderr-Ausgabe.

## Siehe auch

- [Fehlgeschlagene Bausteine in den Aktivitäten](./baustein-fehler-aktivitaeten.md)
- [Anwendungsprotokoll](./anwendungsprotokoll.md)
