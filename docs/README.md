# Docs

Projektdokumentation für novooa nach der **Zettelkasten-Methode**: atomare
Notizen in [`notes/`](./notes/), geordnet über Inhaltsverzeichnisse in
[`index/`](./index/). Einstieg für Agenten und Contributors ist
[`../AGENTS.md`](../AGENTS.md).

## Inhaltsverzeichnisse

| Thema | Verzeichnis |
| --- | --- |
| Architektur | [`index/architektur.md`](./index/architektur.md) |
| Lokale Runtime | [`index/lokale-runtime.md`](./index/lokale-runtime.md) |
| Betrieb und Deployment | [`index/betrieb-und-deployment.md`](./index/betrieb-und-deployment.md) |
| Produkt | [`index/produkt.md`](./index/produkt.md) |
| Aufgabe | [`index/aufgabe.md`](./index/aufgabe.md) |
| Zeitplan | [`index/zeitplan.md`](./index/zeitplan.md) |
| Aktivitäten | [`index/aktivitaeten.md`](./index/aktivitaeten.md) |
| Dateien | [`index/dateien.md`](./index/dateien.md) |
| Daten | [`index/daten.md`](./index/daten.md) |
| Wissensbasis | [`index/wissensbasis.md`](./index/wissensbasis.md) |
| KI-Agent | [`index/ki-agent.md`](./index/ki-agent.md) |
| Fähigkeiten | [`index/faehigkeiten.md`](./index/faehigkeiten.md) |
| Mitarbeiter | [`index/mitarbeiter.md`](./index/mitarbeiter.md) |
| ML-Modelle | [`index/ml-modelle.md`](./index/ml-modelle.md) |
| Sprachausgabe | [`index/sprachausgabe.md`](./index/sprachausgabe.md) |
| Dokumentenscanner | [`index/dokumentscanner.md`](./index/dokumentscanner.md) |
| Kommunikation | [`index/kommunikation.md`](./index/kommunikation.md) |
| Integrationen | [`index/integrationen.md`](./index/integrationen.md) |
| Webhooks | [`index/webhooks.md`](./index/webhooks.md) |
| Verbindungen | [`index/verbindungen.md`](./index/verbindungen.md) |
| Import/Export | [`index/import-export.md`](./index/import-export.md) |

Das Designsystem bleibt als eigenes Dokument: [`DESIGN.md`](./DESIGN.md).

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
- Eine Notiz darf zu mehreren Inhaltsverzeichnissen gehören
  (`Gehört zu: [A](…) · [B](…)`).
- Nicht umgesetzte Teile werden ausdrücklich als „geplant“ markiert.

**Inhaltsverzeichnis** (`index/<thema>.md`): Kernaussage des Themas, danach
gruppierte Links auf Notizen, „Offene Punkte“ und „Verwandt“. Kaum eigener
Inhalt.

**Neues Thema oder Feature:** Notizen anlegen, ein Inhaltsverzeichnis anlegen
oder ergänzen, in dieser README und in `AGENTS.md` § Doc-Index eintragen.

`flutter test test/docs` prüft, dass jeder relative Link existiert, jede Notiz
Titel, Kernaussage und „Gehört zu“ hat und in mindestens einem
Inhaltsverzeichnis steht.

## Konvention: Doc-Update im Commit

- API- oder Modell-Änderungen → zugehörige Notiz im **selben** Commit.
- Reine Doku-Fixes → Commit-Prefix `docs:`.
- Neue Notiz → Eintrag im passenden Inhaltsverzeichnis im selben Commit.
