# Script-Dienst: Ausführung und Grenzen

> Jeder Lauf bekommt einen frischen `python -I`-Prozess mit eigenem temporärem Verzeichnis und vollem Python, begrenzt auf 10 s.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Volles Python (Imports, `open`, Standardbibliothek); das Script läuft als
  `__main__`, ein `if __name__ == "__main__":`-Block wird ausgeführt.
- Bereit stehen Variablen früherer Bausteine, `files`, `list_files()`,
  `read_file()` und `workflow_output()`.
- Grenzen je Lauf: 10 s (`SCRIPT_TIMEOUT_SECONDS`), 64 MB Dateigröße,
  128 offene Dateien, 64 Prozesse/Threads (`SCRIPT_MAX_PROCESSES`).
  Höchstens vier Läufe gleichzeitig.
- **Kein Speicherlimit je Prozess** (kein `RLIMIT_AS`): Das Script darf den
  Speicher des Containers nutzen. Wird er knapp, beendet der Kernel zuerst die
  Scripts (`oom_score_adj=1000`), nie den Server. Meldung: „Das Script wurde
  beendet (Signal 9), etwa wegen zu hohem Speicher- oder Zeitverbrauch.“
- Das Arbeitsverzeichnis wird danach gelöscht.

## Siehe auch

- [Script-Dienst: Ressourcengrenzen abstimmen](./script-dienst-ressourcen.md)
- [Script-Ausgabe im Protokoll](./script-ausgabe-protokoll.md)
- [Script-Dienst: Schnittstelle](./script-dienst-schnittstelle.md)
