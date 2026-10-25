# SQLite-Prüfstand (3NF)

> Alle 28 Anwendungstabellen sind gegen fachliche funktionale Abhängigkeiten geprüft; vollständige strenge 3NF ist nicht bestätigt, JSON-Aggregate und Historie sind ausdrücklich benannt.

Gehört zu: [Architektur](../index/architektur.md) · [Lokale Runtime](../index/lokale-runtime.md)

Stand: Migration `0019`. Schema in
[`core.ts`](../../functions/src/db/models/core.ts),
[`integration.ts`](../../functions/src/db/models/integration.ts),
[`resources.ts`](../../functions/src/db/models/resources.ts);
`__drizzle_migrations` gehört nicht zum Fachmodell.

**Maßstab:** Für jede nichttriviale Abhängigkeit `X → A` ist `X`
Superschlüssel oder `A` Teil eines Kandidatenschlüssels. Anzeigenamen,
E-Mails, Pfade und Provider-Modellnamen sind keine impliziten Schlüssel. Eine
JSON-Spalte allein ist kein Verstoß; Historie wird nach ihrem damaligen
Zeitpunkt beurteilt. **3NF-Basis** = keine weitere partielle oder transitive
Abhängigkeit gefunden; **Historie/JSON** = bewusste Aggregate oder
Herkunftsdaten.

| Tabelle | Schlüssel / Abhängigkeit | Bewertung |
| --- | --- | --- |
| `activities` | `id → Rest`; Run bestimmt Team, Aufgabe | seit `0014` entdoppelt; wiederholte Bausteinmetadaten noch prüfen |
| `task_run_jobs` | `id`, eindeutiges `run_id` | 3NF-Basis (`0012`) |
| `task_run_steps` | `(run_id, step_path) → Ergebnis, Zeit` | 3NF-Basis; Ergebnis JSON |
| `task_runs` | `id → Zustand, Snapshots` | Historie/JSON; `task_id → team_id` bewusste Herkunftsredundanz |
| `task_triggers` | `id → Rest`; Aufgabe bestimmt Team | 3NF-Basis (`0013`) |
| `tasks` | `id → Rest` | 3NF-Basis; Graph als Konfiguration |
| `user_profiles` | `uid → Profil` | 3NF-Basis (`0011`) |
| `team_members` | `(team_id, uid) → Rolle, Zeiten` | 3NF-Basis (`0011`) |
| `teams` | `id → Name, Eigentümer, Zeiten` | 3NF-Basis |
| `application_logs` | `id → Ereignis` | 3NF-Basis; `data_json` historisch |
| `connections` | `id → Verbindung` | 3NF-Basis; Geheimnis separat |
| `communication_channels` | `id → Kanal` | 3NF-Basis |
| `inbound_channel_events` | `event_id`, `(team_id, provider, provider_message_id)` | Historie/JSON |
| `language_model_connections` | `id → Verbindung` | 3NF-Basis |
| `language_model_defaults` | `team_id → Modellwahl je Zweck` | 3NF-Basis; Referenzen separat prüfen |
| `language_model_secrets` | `secret_ref → Envelope, Zeit` | 3NF-Basis |
| `language_models` | `id → Profil`; Verbindung bestimmt Team | 3NF-Basis (`0010`) |
| `model_catalog` | `id → Rest`; Team-ID bestimmt Bereich | `0015`; Aggregate für Übersetzungen, Tags, Artefakt, Vertrag |
| `runtime_access_credential` | festes `id = 1` | eine Zugangskonfiguration |
| `runtime_sessions` | `token_hash → Anlage, Ablauf` | 3NF-Basis |
| `document_collections` | `(team_id, id)`, `(team_id, display_name)` | 3NF-Basis |
| `documents` | `(team_id, collection_id, id) → Dokument, Version, Zeiten` | 3NF-Basis der Hülle |
| `file_folders` | `id → Rest` | 3NF-Basis (`0018`) |
| `workspace_file_settings` | `team_id → version_limit` | 3NF-Basis |
| `file_versions` | `id → Version` | 3NF-Basis (`0009`) |
| `files` | `id → Datei` | 3NF-Basis (`0017`) |
| `knowledge_notes` | `id → Notiz` | 3NF-Basis (`0019`) |
| `employees` | `id → Konfiguration` | 3NF-Basis der Hülle; `skills_json` sind externe Namen |

`0016` brachte zusammengesetzte Fremdschlüssel und Zyklusprüfung für Ordner
und Dateiablage (Integrität, noch keine Auflösung der Teamredundanz; die kam
mit `0017`/`0018`).

**Verbleibend:** wiederholte Bausteinmetadaten in Aktivitäten und
Herkunftsredundanz in Runs historisch sinnvoll zerlegen; fehlende
referentielle Absicherung von Modellvorgaben und Eigentümerbezügen getrennt
von der Normalform prüfen.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [Runtime-Schichten](./runtime-schichten.md)
