# Aktivitäten eines Runs

> Pro Run entstehen eine Start-Aktivität, je Baustein eine Node-Aktivität und eine Abschluss-Aktivität, sofern der Run nicht wartet.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

- Task-Aktivität `started` mit Run-ID und Eingabekontext.
- Je Baustein eine Node-Aktivität: `succeeded`, `skipped` oder `waiting`
  (bei Fehlern siehe [Fehlgeschlagene Bausteine](./baustein-fehler-aktivitaeten.md)).
- Abschluss `succeeded` oder `failed`, außer der Run wartet auf Freigabe.

Cloud:

```text
teams/{teamId}/taskRuns/{runId}
teams/{teamId}/activities/{activityId}
```

Der Client liest über `FirestoreTaskActivityRepository` und
`FirestoreTaskRunRepository`; `teamId` über `users/{uid}.teamId`, damit die
Tabs ohne aktive Backend-Wartezeit rendern. Domain-Modell: `TaskActivity`.

Wartende Runs (`waitingForApproval`) tragen für die Interaktions-UI:

```text
interaction        # Art und Definition: Freigabe, Formular oder Medienaufnahme
reviewOutput       # editierbarer Output des vorherigen Bausteins
resumeState        # serialisierter Zwischenzustand
```

Standalone: siehe [Aktivitäten über den Run (0014)](./sqlite-aktivitaeten-normalisiert.md).

## Siehe auch

- [Aktivitäten-Seite](./aktivitaeten-seite.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
