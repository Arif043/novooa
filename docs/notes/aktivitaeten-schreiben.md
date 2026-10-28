# Aktivitäten eines Runs

> Pro Run entstehen eine Start-Aktivität, je Baustein eine Node-Aktivität und eine Abschluss-Aktivität, sofern der Run nicht wartet.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

- Task-Aktivität `started` mit Run-ID und Eingabekontext.
- Je Baustein eine Node-Aktivität: `succeeded`, `skipped` oder `waiting`
  (bei Fehlern siehe [Fehlgeschlagene Bausteine](./baustein-fehler-aktivitaeten.md)).
  Eine Teamarbeit trägt zusätzlich ihr Gespräch (`conversation`, siehe
  [Ausführung der Teamarbeit](./teamwork-ausfuehrung.md)). Jede Node-Aktivität
  trägt ihre [Folgen](./lauf-effekte.md) (`effects`), auch bei Fehlern.
- Abschluss `succeeded` oder `failed`, außer der Run wartet auf Freigabe.

Domain-Modell: `TaskActivity`; gespeichert in SQLite, siehe
[Aktivitäten über den Run (0014)](./sqlite-aktivitaeten-normalisiert.md).

Wartende Runs (`waitingForApproval`) tragen für die Interaktions-UI:

```text
interaction        # Art und Definition: Freigabe, Formular oder Medienaufnahme
reviewOutput       # editierbarer Output des vorherigen Bausteins
resumeState        # serialisierter Zwischenzustand
```

## Siehe auch

- [Aktivitäten-Seite](./aktivitaeten-seite.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
