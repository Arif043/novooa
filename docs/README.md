# Docs

Projektdokumentation für novooa. Diese Docs sind **feature-first** organisiert:
pro Feature ein Deep-Dive in `features/`, cross-cutting-Themen in
[`architecture.md`](./architecture.md).

## Struktur

| Bereich        | Datei                              | Inhalt                                                  |
| -------------- | ---------------------------------- | ------------------------------------------------------- |
| Überblick      | [`../AGENTS.md`](../AGENTS.md)     | Projekt-Definition, Stack, Conventions, Agent-Regeln    |
| Cross-cutting  | [`architecture.md`](./architecture.md) | Datenmodell, Auth, Persistenz, Trigger, Telemetrie   |
| Deployment | [`deployment.md`](./deployment.md) | Staging/Produktion, Firebase-Projekte und CI/CD |
| Backend        | [`backend-struktur.md`](./backend-struktur.md) | Functions-Struktur, Ports, Cloud-/Local-Trennung |
| Executor-Outputs | [`node-executor-outputs.md`](./node-executor-outputs.md) | Output-Vertraege der Workflow-Executoren |
| Lokale Runtime | [`local-runtime.md`](./local-runtime.md) | Docker-Deployment, Datenhaltung, Ports und Relay |
| Betriebsvarianten | [`architecture/betriebsvarianten.md`](./architecture/betriebsvarianten.md) | Clients × Cloud/Standalone: Ist-Zustand, Blocker, Umsetzung |
| Features       | [`features/`](./features/)         | Ein Deep-Dive pro Feature                               |

## Aktuelle Features

| Feature         | Doc                                                       | Status         |
| --------------- | --------------------------------------------------------- | -------------- |
| Aufgabe         | [`features/aufgabe.md`](./features/aufgabe.md)            | In Entwicklung |
| Aufgabe: Ausfuehrung | [`features/aufgabe-ausfuehrung.md`](./features/aufgabe-ausfuehrung.md) | Runner, Freigaben, lokale Ausfuehrung |
| Aufgabe: Executor | [`features/aufgabe-executoren.md`](./features/aufgabe-executoren.md) | Modellprovider und Executor-Verhalten |
| Kommunikation   | [`features/kommunikation.md`](./features/kommunikation.md)   | System-E-Mail und Kundenpostfach-Connectoren |
| Arbeitspläne    | [`features/arbeitsplaene.md`](./features/arbeitsplaene.md) | Stub           |
| Zeitplan        | [`features/zeitplan.md`](./features/zeitplan.md)          | Zeitbasierte Trigger |
| Aktivitäten     | [`features/aktivitaeten.md`](./features/aktivitaeten.md)  | Stub           |
| Dateien         | [`features/dateien.md`](./features/dateien.md)            | In Entwicklung |
| Daten           | [`features/daten.md`](./features/daten.md)                | Fachlogik und lokaler Store |
| Wissensbasis    | [`features/wissensbasis.md`](./features/wissensbasis.md)  | In Entwicklung |
| KI-Agent        | [`features/ki-agent.md`](./features/ki-agent.md)          | In Entwicklung |
| ML-Modelle      | [`features/ml-modelle.md`](./features/ml-modelle.md)      | Katalog und Vertrag |

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
