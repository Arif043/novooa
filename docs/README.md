# Docs

Projektdokumentation für Syscat. Diese Docs sind **feature-first** organisiert:
pro Feature ein Deep-Dive in `features/`, cross-cutting-Themen in
[`architecture.md`](./architecture.md).

## Struktur

| Bereich        | Datei                              | Inhalt                                                  |
| -------------- | ---------------------------------- | ------------------------------------------------------- |
| Überblick      | [`../AGENTS.md`](../AGENTS.md)     | Projekt-Definition, Stack, Conventions, Agent-Regeln    |
| Cross-cutting  | [`architecture.md`](./architecture.md) | Datenmodell, Auth, Persistenz, Trigger, Telemetrie   |
| Features       | [`features/`](./features/)         | Ein Deep-Dive pro Feature                               |

## Aktuelle Features

| Feature         | Doc                                                       | Status         |
| --------------- | --------------------------------------------------------- | -------------- |
| Aufgabe         | [`features/aufgabe.md`](./features/aufgabe.md)            | In Entwicklung |
| Arbeitspläne    | [`features/arbeitsplaene.md`](./features/arbeitsplaene.md) | Stub           |
| Zeitplan        | [`features/zeitplan.md`](./features/zeitplan.md)          | Stub           |
| Aktivitäten     | [`features/aktivitaeten.md`](./features/aktivitaeten.md)  | Stub           |
| Dateien         | [`features/dateien.md`](./features/dateien.md)            | In Entwicklung |

## Konvention: Neue Feature-Doc anlegen

1. Datei `docs/features/<slug>.md` anlegen.
2. Top-Sektion: `## Zweck` (1 Absatz).
3. Sektion `## Verantwortlichkeiten` mit Aufzählungspunkten.
4. Sektion `## Offene Fragen` für ungeklärte Design-Punkte.
5. Sektion `## Verwandt` mit relativen Links zu Nachbar-Features und
   `architecture.md`.
6. In [`../AGENTS.md`](../AGENTS.md) § Doc-Index und in dieser README
   eintragen.

## Konvention: Doc-Update im Commit

- API- oder Modell-Änderungen → zugehörige Doc im **selben** Commit.
- Reine Doku-Fixes → Commit-Prefix `docs:`.
- Neue Datei unter `docs/features/` → Eintrag in dieser README **und** in
  `AGENTS.md` § Doc-Index im selben Commit.
