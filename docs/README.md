# Docs

Projektdokumentation für novooa. Die Docs werden **featureweise** auf die
Zettelkasten-Methode umgestellt: atomare Notizen in [`notes/`](./notes/),
geordnet über Inhaltsverzeichnisse in [`index/`](./index/). Noch nicht
umgestellte Features liegen als Deep-Dive in `features/`, cross-cutting-Themen
in [`architecture.md`](./architecture.md).

## Inhaltsverzeichnisse

| Thema    | Verzeichnis                              |
| -------- | ---------------------------------------- |
| Zeitplan | [`index/zeitplan.md`](./index/zeitplan.md) |
| Lokale Runtime | [`index/lokale-runtime.md`](./index/lokale-runtime.md) |
| ML-Modelle | [`index/ml-modelle.md`](./index/ml-modelle.md) |
| Aufgabe | [`index/aufgabe.md`](./index/aufgabe.md) |
| Dateien | [`index/dateien.md`](./index/dateien.md) |
| KI-Agent | [`index/ki-agent.md`](./index/ki-agent.md) |

## Zettelkasten-Regeln

**Atomare Notiz** (`notes/<sprechender-name>.md`):

- Ein Gedanke pro Notiz, für sich verständlich, höchstens 200 Zeilen
  (Richtwert 20–80).
- Dateiname = Titel in `kebab-case`, deutsch, ohne Umlaute
  (`ausloeser-dialog.md`). Ordner bleibt flach, keine Unterordner.
- Aufbau:

  ```markdown
  # Titel

  > Kernaussage in einem Satz.

  Gehört zu: [Thema](../index/<thema>.md)

  Inhalt …

  ## Siehe auch

  - [Andere Notiz](./andere-notiz.md) — warum sie relevant ist
  ```

- Wissen steht nur an einer Stelle; andere Notizen verlinken darauf.
- Eine Notiz darf zu mehreren Inhaltsverzeichnissen gehören.

**Inhaltsverzeichnis** (`index/<thema>.md`): Kernaussage des Themas, danach
gruppierte Links auf Notizen, „Offene Punkte“ und „Verwandt“. Kaum eigener
Inhalt.

**Feature umstellen:** Deep-Dive in Notizen zerlegen, Inhaltsverzeichnis
anlegen, alte Datei löschen, alle Verweise (auch in `AGENTS.md`) umbiegen.
`flutter test test/docs` prüft, dass jeder relative Link existiert, jede Notiz
„Gehört zu“ hat und in mindestens einem Inhaltsverzeichnis steht.

## Struktur

| Bereich        | Datei                              | Inhalt                                                  |
| -------------- | ---------------------------------- | ------------------------------------------------------- |
| Überblick      | [`../AGENTS.md`](../AGENTS.md)     | Projekt-Definition, Stack, Conventions, Agent-Regeln    |
| Cross-cutting  | [`architecture.md`](./architecture.md) | Datenmodell, Auth, Persistenz, Trigger, Telemetrie   |
| SQLite-Normalisierung | [`architecture/sqlite-normalisierung.md`](./architecture/sqlite-normalisierung.md) | Prüfung aller Tabellen, Migrationen und verbleibende Abhängigkeiten |
| Deployment | [`deployment.md`](./deployment.md) | Staging/Produktion, Firebase-Projekte und CI/CD |
| Backend        | [`backend-struktur.md`](./backend-struktur.md) | Functions-Struktur, Ports, Cloud-/Local-Trennung |
| Lokale Runtime | [`index/lokale-runtime.md`](./index/lokale-runtime.md) | Zettelkasten: Stack, Zugriff, Datenhaltung, Lizenz, Relays |
| Betriebsvarianten | [`architecture/betriebsvarianten.md`](./architecture/betriebsvarianten.md) | Clients × Cloud/Standalone: Ist-Zustand, Blocker, Umsetzung |
| Features       | [`features/`](./features/)         | Ein Deep-Dive pro Feature                               |

## Aktuelle Features

| Feature         | Doc                                                       | Status         |
| --------------- | --------------------------------------------------------- | -------------- |
| Aufgabe         | [`index/aufgabe.md`](./index/aufgabe.md)                  | Zettelkasten       |
| Kommunikation   | [`features/kommunikation.md`](./features/kommunikation.md)   | System-E-Mail und Kundenpostfach-Connectoren |
| Zeitplan        | [`index/zeitplan.md`](./index/zeitplan.md)                | Zettelkasten       |
| Aktivitäten     | [`features/aktivitaeten.md`](./features/aktivitaeten.md)  | Stub           |
| Dateien         | [`index/dateien.md`](./index/dateien.md)                | Zettelkasten       |
| Daten           | [`features/daten.md`](./features/daten.md)                | Fachlogik und lokaler Store |
| Wissensbasis    | [`features/wissensbasis.md`](./features/wissensbasis.md)  | In Entwicklung |
| KI-Agent        | [`index/ki-agent.md`](./index/ki-agent.md)               | Zettelkasten       |
| ML-Modelle      | [`index/ml-modelle.md`](./index/ml-modelle.md)            | Zettelkasten       |
| Sprachausgabe   | [`features/sprachausgabe.md`](./features/sprachausgabe.md) | Text vorlesen über Sprachmodelle, Stimmen |
| Import/Export   | [`features/import-export.md`](./features/import-export.md) | Standalone: Sicherung und Übertragung |

## Konvention: Neue Feature-Doc anlegen

Neue Features bekommen direkt Notizen und ein Inhaltsverzeichnis (siehe oben).
Das alte Schema gilt nur noch für Ergänzungen nicht umgestellter Deep-Dives:

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
