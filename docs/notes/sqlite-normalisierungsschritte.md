# SQLite-Normalisierungsschritte

> Ab Migration `0010` werden doppelte Team-Bezüge entfernt; das Team ergibt sich über Fremdschlüssel aus dem fachlichen Elternobjekt.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Gemeinsames Muster: JSON-Konfigurationen und historische Snapshots bleiben,
Domain-Verträge und Firestore-Adapter ändern sich nicht. Eine vollständige
strenge 3NF wird nicht behauptet.

| Migration | Kern |
| --- | --- |
| `0010` Sprachmodelle | Profile ohne `team_id`; Team über `language_model_connections`. [Notiz](./sqlite-sprachmodelle-normalisiert.md) |
| `0011` Teammitglieder | `user_profiles` je `uid`, `team_members` nur Zuordnung. [Notiz](./sqlite-teammitglieder-normalisiert.md) |
| `0012` Run-Abhängige | Jobs und Schritte über `run_id`. [Notiz](./sqlite-run-abhaengige-normalisiert.md) |
| `0013` Auslöser | Team über `task_id`. [Notiz](./ausloeser-standalone-aufgabenbezug.md) |
| `0014` Aktivitäten | Team und Aufgabe über `run_id`. [Notiz](./sqlite-aktivitaeten-normalisiert.md) |
| `0015` Modellkatalog | `team_id = NULL` = Systemmodell. [Notiz](./sqlite-modellkatalog-normalisiert.md) |
| `0017`/`0018` Dateien, Ordner | genau eine Ablage, Team über Elternkette. [Notiz](./sqlite-dateiablage-normalisiert.md) |
| `0019` Wissenslinks | Links werden beim Lesen berechnet. [Notiz](./sqlite-wissenslinks-berechnet.md) |

Dateiversionen: [Dateiversionen in SQLite (0009)](./sqlite-dateiversionen-normalisiert.md).

## Siehe auch

- [SQLite-Prüfstand (3NF)](./sqlite-3nf-pruefstand.md) — Prüfstand aller 28 Tabellen
- [SQLite-Migrationen](./sqlite-migrationen.md)
