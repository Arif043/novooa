# Feature: Mitarbeiter (Subagenten)

Verwandt: [`aufgabe`](../index/aufgabe.md) · [`skills.md`](./skills.md) · [`import-export.md`](./import-export.md)

## Zweck

Ein Mitarbeiter ist ein wiederverwendbarer Subagent: eine **Rahmenbedingung** plus eine Menge **Fähigkeiten**
([Skills](./skills.md)). Die Rahmenbedingung ist unter der Haube der **System-Prompt** des LLM-Calls; die Fähigkeiten
erhält der Agent implizit. Ausgeführt wird er mit der Genkit-Agent-API
([`ai.defineAgent`](https://genkit.dev/docs/js/agents/overview/), Beta).

Mitarbeiter sind **kein eigener Baustein**, sondern werden 0..1 an einen Baustein zugewiesen — heute an `Prompt` und
`Iterative Verfeinerung`.

**Mitarbeiter und Fähigkeiten schließen sich aus:** Ein Baustein hat entweder einen Mitarbeiter (dessen Fähigkeiten er
dann bekommt) oder selbst gewählte Fähigkeiten, nie beides.

**Verfügbarkeit:** Standalone (lokale Runtime, `WorkspaceCapabilities.employees`). In der Cloud ist das Feature aus,
weil es dort keine Fähigkeiten gibt.

## Datenmodell

SQLite-Tabelle `employees` (Migration `0002_employees.sql`), je Team:

| Feld              | Bedeutung                                                                      |
| ----------------- | ------------------------------------------------------------------------------ |
| `id`              | UUID                                                                           |
| `name`            | Anzeigename, 1–80 Zeichen, je Team eindeutig (ohne Groß-/Kleinschreibung)       |
| `constraint_text` | Rahmenbedingung (System-Prompt), höchstens 8000 Zeichen, darf leer sein         |
| `skills_json`     | Namen der Fähigkeiten (Ordnernamen im Skills-Verzeichnis), höchstens 50          |
| `created_at`, `updated_at` | ISO-Zeitstempel                                                       |

Es gibt **keine Prompt-Vorlage**: Die Anweisung des Bausteins geht unverändert als Nutzer-Nachricht an den Agenten.

## HTTP-API (lokale Runtime)

| Route                        | Zweck                                                          |
| ---------------------------- | -------------------------------------------------------------- |
| `GET /v1/employees`          | Liste, alphabetisch                                            |
| `POST /v1/employees`         | anlegen `{name, constraint, skills}`                           |
| `PUT /v1/employees/:id`      | ändern                                                         |
| `DELETE /v1/employees/:id`   | löschen                                                        |

Fehler sind lesbar: 400 bei ungültiger Eingabe, 409 bei doppeltem Namen, 404 bei unbekannter ID. Änderungen meldet das
Realtime-Thema `employees`.

## Zuweisung an einen Baustein

`PromptNodeConfig` und `IterativeRefinementNodeConfig` halten **nur die ID**:

```json
{"primitive": "prompt", "employeeId": "3f1c…", "skillAttachments": []}
```

Rahmenbedingung und Fähigkeiten werden **beim Lauf frisch geladen**: Änderungen am Mitarbeiter gelten sofort für alle
Bausteine, die ihn verwenden. Gibt es ihn nicht mehr, bricht der Baustein mit „Der zugewiesene Mitarbeiter wurde nicht
gefunden. Wurde er gelöscht? …“ ab; die Meldung steht in der Aktivität. Im Baustein zeigt die Oberfläche dann
„Mitarbeiter nicht mehr vorhanden“.

### Ausschließlichkeit

Die Regel gilt an drei Stellen:
- **Config (Flutter):** `resolveNodeDelegation` — wer zuletzt etwas Konkretes setzt, gewinnt. `assignEmployee` leert die
  Fähigkeiten, `attachSkill` entfernt den Mitarbeiter; eine leere Fähigkeitenliste lässt den Mitarbeiter bestehen.
  Der Mapper bereinigt Dokumente, die beides tragen (der Mitarbeiter gewinnt).
- **Oberfläche:** Das gemeinsame Auswahlfeld (Segmente *Fähigkeiten | Mitarbeiter*, in `Prompt` und
  `Iterative Verfeinerung`) räumt beim Wechsel die andere Seite auf und weist darauf hin.
- **Ausführung (Backend):** `assertExclusiveDelegation` lehnt Bausteine mit beidem ab („Ein Baustein kann nicht zugleich
  einen Mitarbeiter und Fähigkeiten haben …“), bevor irgendetwas angelegt wird.

## Ausführung im TaskRun

1. [`prepareNodeAttachmentWorkspace`](../../functions/src/features/task_execution/infrastructure/genkit/runner/node-attachment-workspace.ts)
   lädt den Mitarbeiter über den `EmployeeStore` (Teil der `TaskGraphRuntime`, nicht der `TaskRunServices`) und legt
   `workspace.employee = {id, name, constraint}` ab. **Seine Fähigkeiten ersetzen die des Bausteins** und werden als
   Ordner nach `<workspace>/skills/<name>/` kopiert. Ein Mitarbeiter ohne Fähigkeiten erzeugt trotzdem einen
   Workspace, damit die Rahmenbedingung ankommt.
2. [`employee-agent.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/employee-agent.ts)
   definiert einen Agenten `defineAgent({name, system: constraint, model, use, output, config})` und führt einen Turn
   mit `chat().send(anweisung)` aus. `use` reicht die Retry-, Dateisystem- und Skill-Middleware durch; die Fähigkeiten
   des Mitarbeiters bietet `use_skill` dem Modell an. Eine leere Rahmenbedingung sendet keinen System-Prompt.
3. **Kind-Registry:** `defineAgent` registriert fünf Actions je Agent. Auf der Registry der langlebigen Runtime würden sie
   nie wieder verschwinden (Messung: 2 → 17 Actions nach drei Agenten). Der Agent liegt deshalb in
   `Registry.withParent(ai.registry)`; Modelle und Plugins löst das Kind über seine Eltern auf, es wird mit dem Turn
   geräumt. Ein Test belegt, dass die Registry nach fünf Turns unverändert groß ist. Der Name bleibt mit einer UUID
   eindeutig.
4. Es gibt keinen Session-Store: pro Turn ein frischer Chat ohne gespeicherten Verlauf.

Bausteine mit Bildern im Prompt gehen unverändert über den bewährten `generate`-Pfad, ohne Agent.

## UI

Route `/employees`, Drawer-Label **Mitarbeiter** (nur Standalone). Liste mit Name, gekürzter Rahmenbedingung und Anzahl
der Fähigkeiten; Löschen mit Bestätigung (Hinweis auf betroffene Bausteine). Der Editor ist ein adaptives Sheet mit
*Name*, *Rahmenbedingung* (Hinweis „Gilt als System-Prompt für jeden Aufruf.“) und *Fähigkeiten* (Auswahl aus den
vorhandenen Skills; Namen, die es nicht mehr gibt, bleiben als „Nicht mehr vorhanden“ sichtbar und lassen sich
entfernen). Alle Texte deutsch, Zustände Laden/Fehler/Leer/Erfolg.

## Sicherung und Umzug

Der Workspace-Transfer kennt den Bereich **Mitarbeiter** (zwischen Fähigkeiten und Aufgaben). Gleiche IDs werden
überschrieben; ein gleicher Name unter anderer ID bekommt ein „ (2)“. Fehlende Fähigkeiten im Ziel meldet der spätere
Lauf klar (siehe [`import-export.md`](./import-export.md)).

## Offen

- Cloud-Variante (Firestore) — zusammen mit einem Cloud-Speicher für Skills.
- Weitere LLM-Bausteine als Ziel einer Zuweisung; Agent-Sitzungen mit Verlauf.

## Definition of Done

- [x] Mitarbeiter lassen sich anlegen, bearbeiten und löschen (Name, Rahmenbedingung, Fähigkeiten).
- [x] Zuweisung an Prompt und Iterative Verfeinerung per ID; Mitarbeiter und Fähigkeiten schließen sich aus.
- [x] Backend nutzt `ai.defineAgent` + `chat().send` mit der Rahmenbedingung als System-Prompt und den Fähigkeiten des
      Mitarbeiters über die Genkit-Skill-Middleware.
- [x] Mitarbeiter sind Teil von Export und Import.
- [x] `flutter analyze` und `npm --prefix functions run build` sind sauber.
