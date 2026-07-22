# Docs

Projektdokumentation für Syscat. Diese Docs sind **feature-first** organisiert:
pro Feature ein Deep-Dive in `features/`, cross-cutting-Themen in
[`architecture.md`](./architecture.md).

## Struktur

| Bereich        | Datei                              | Inhalt                                                  |
| -------------- | ---------------------------------- | ------------------------------------------------------- |
| Überblick      | [`../AGENTS.md`](../AGENTS.md)     | Projekt-Definition, Stack, Conventions, Agent-Regeln    |
| Cross-cutting  | [`architecture.md`](./architecture.md) | Datenmodell, Auth, Persistenz, Trigger, Telemetrie   |
| Backend        | [`backend-struktur.md`](./backend-struktur.md) | Functions-Struktur, Ports, Cloud-/Local-Trennung |
| Executor-Outputs | [`node-executor-outputs.md`](./node-executor-outputs.md) | Output-Vertraege der Workflow-Executoren |
| Lokale Runtime | [`local-runtime.md`](./local-runtime.md) | Lokale Datenhaltung, Ports, Relay-Strategie       |
| Features       | [`features/`](./features/)         | Ein Deep-Dive pro Feature                               |

## Aktuelle Features

| Feature         | Doc                                                       | Status         |
| --------------- | --------------------------------------------------------- | -------------- |
| Aufgabe         | [`features/aufgabe.md`](./features/aufgabe.md)            | In Entwicklung |
| Aufgabe: Ausfuehrung | [`features/aufgabe-ausfuehrung.md`](./features/aufgabe-ausfuehrung.md) | Runner, Freigaben, lokale Ausfuehrung |
| Aufgabe: Executor | [`features/aufgabe-executoren.md`](./features/aufgabe-executoren.md) | Modellprovider und Executor-Verhalten |
| Arbeitspläne    | [`features/arbeitsplaene.md`](./features/arbeitsplaene.md) | Stub           |
| Zeitplan        | [`features/zeitplan.md`](./features/zeitplan.md)          | Zeitbasierte Trigger |
| Aktivitäten     | [`features/aktivitaeten.md`](./features/aktivitaeten.md)  | Stub           |
| Dateien         | [`features/dateien.md`](./features/dateien.md)            | In Entwicklung |
| Wissensbasis    | [`features/wissensbasis.md`](./features/wissensbasis.md)  | In Entwicklung |
| KI-Agent        | [`features/ki-agent.md`](./features/ki-agent.md)          | In Entwicklung |

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
