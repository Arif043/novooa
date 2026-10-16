# Mitarbeiter

> Ein Mitarbeiter ist ein wiederverwendbarer Subagent aus Rahmenbedingung (System-Prompt) und Fähigkeiten; Bausteine verweisen nur per ID auf ihn.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md) · [Lokale Runtime](../index/lokale-runtime.md)

- Kein eigener Baustein, sondern 0..1 an `Prompt` oder `Iterative
  Verfeinerung` zugewiesen.
- **Verfügbarkeit:** Standalone (`WorkspaceCapabilities.employees`); in der
  Cloud aus, weil es dort keine Fähigkeiten gibt.
- Keine Prompt-Vorlage: Die Anweisung des Bausteins geht unverändert als
  Nutzer-Nachricht an den Agenten.

SQLite-Tabelle `employees` (Migration `0002_employees.sql`), je Team:

| Feld | Bedeutung |
| --- | --- |
| `id` | UUID |
| `name` | 1–80 Zeichen, je Team eindeutig (ohne Groß-/Kleinschreibung) |
| `constraint_text` | Rahmenbedingung, höchstens 8000 Zeichen, darf leer sein |
| `skills_json` | Namen der Fähigkeiten (Ordnernamen), höchstens 50 |
| `created_at`, `updated_at` | ISO-Zeitstempel |

| Route | Zweck |
| --- | --- |
| `GET /v1/employees` | Liste, alphabetisch |
| `POST /v1/employees` | anlegen `{name, constraint, skills}` |
| `PUT /v1/employees/:id` | ändern |
| `DELETE /v1/employees/:id` | löschen |

Fehler: 400 ungültig, 409 doppelter Name, 404 unbekannt. Realtime-Thema
`employees`.

Zuweisung: Die Config hält nur `employeeId`; Rahmenbedingung und Fähigkeiten
lädt der Lauf frisch, Änderungen gelten sofort überall. Gelöscht → „Der
zugewiesene Mitarbeiter wurde nicht gefunden. Wurde er gelöscht? …“ in der
Aktivität; das Panel zeigt „Mitarbeiter nicht mehr vorhanden“.

## Siehe auch

- [Ausschließlichkeit von Mitarbeiter und Fähigkeiten](./mitarbeiter-ausschliesslichkeit.md)
- [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)
- [Mitarbeiter-Seite](./mitarbeiter-seite.md)
