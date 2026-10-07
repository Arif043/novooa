# SQLite: Normalisierung und verbleibende Prüfungen

Stand: Migration `0015_normalize_model_catalog`, 28 Anwendungstabellen.
Die Drizzle-Historie `__drizzle_migrations` gehört nicht zum Fachmodell.

## Bewertungsgrundlage

3NF wird anhand fachlicher funktionaler Abhängigkeiten bewertet, nicht anhand
der Anzahl von Fremdschlüsseln. Für jede nichttriviale Abhängigkeit `X → A`
muss `X` ein Superschlüssel oder `A` Teil eines Kandidatenschlüssels sein.
Zusammengesetzte Schlüssel dürfen keine partiellen Abhängigkeiten verdecken.

Die folgende Prüfung bezieht sich auf das aktuelle Schema in
[`core.ts`](../../functions/src/db/models/core.ts),
[`integration.ts`](../../functions/src/db/models/integration.ts) und
[`resources.ts`](../../functions/src/db/models/resources.ts), einschließlich
der Verwendung in den SQLite-Adaptern. Zusätzliche fachliche Eindeutigkeiten
dürfen nicht ohne Beleg angenommen werden: Anzeigenamen, E-Mail-Adressen,
Dateipfade und Provider-Modellnamen sind keine impliziten Schlüssel.

**3NF-Basis** bedeutet: Unter den aktuellen Fachverträgen wurde keine weitere
partielle oder transitive Abhängigkeit der relationalen Attribute festgestellt.
**Historie/JSON** benennt bewusst gespeicherte Aggregate oder Herkunftsdaten;
diese Bewertung bestätigt keine vollständige Normalisierung ihres Innenlebens.
**Offen** bezeichnet eine konkrete noch zu klärende Abhängigkeit.
Fehlende Fremdschlüssel sind separat als Integritätsfragen aufgeführt.

JSON wird als ein fachlicher Dokument-/Konfigurationswert behandelt. Eine
JSON-Spalte allein beweist keinen 3NF-Verstoß. Stabile Beziehungen innerhalb
eines Dokuments müssen trotzdem geprüft werden, wenn sie eigenständig
abgefragt oder verändert werden. Historische Werte werden nach ihrem damaligen
Zeitpunkt beurteilt, nicht als Kopien des aktuellen Aufgaben- oder Modellstands.

## Prüfung aller Tabellen

Bei `id → Rest` hängen die übrigen relationalen Attribute vom angegebenen
Schlüssel ab. Die Spalte „Bewertung“ ergänzt Ausnahmen und Prüfpunkte.

| Tabelle | Schlüssel / bekannte Abhängigkeit | Bewertung |
| --- | --- | --- |
| `activities` | `id → Rest`; Run bestimmt Team und Aufgabe | Run-Bezüge seit `0014` entdoppelt. Historie/JSON: wiederholte Bausteinmetadaten innerhalb eines Runs noch auf eigene Abhängigkeiten prüfen. |
| `task_run_jobs` | `id` und eindeutiges `run_id → Rest` | 3NF-Basis; Team über Run seit `0012`. |
| `task_run_steps` | `(run_id, step_path) → Ergebnis, Zeitpunkt` | 3NF-Basis; Ergebnis als JSON-Aggregat, Team seit `0012` abgeleitet. |
| `task_runs` | `id → Ausführungszustand und Snapshots` | Historie/JSON. Aufgaben-ID, damaliges Team und Auslöserherkunft bleiben unabhängig von gelöschten Aufgaben erhalten. Bei dauerhaft globaler Aufgaben-ID gilt weiterhin `task_id → team_id`: bewusste Herkunftsredundanz, keine pauschale strenge 3NF-Bestätigung. |
| `task_triggers` | `id → Rest`; Aufgabe bestimmt Team | 3NF-Basis seit `0013`; Konfiguration/Policy als JSON, letzte Run-ID als historische Referenz. |
| `tasks` | `id → Rest` | 3NF-Basis; Graph als Workflow-Konfiguration. `selected_node_id` bezeichnet UI-Auswahl innerhalb dieses Aggregats. |
| `user_profiles` | `uid → Profilattribute` | 3NF-Basis seit `0011`; E-Mail ist kein deklarierter eindeutiger Schlüssel. |
| `team_members` | `(team_id, uid) → Rolle, Mitgliedschaftszeitpunkte` | 3NF-Basis seit `0011`; keine vom Benutzer allein abhängigen Profilfelder mehr. |
| `teams` | `id → Name, Eigentümer, Zeitpunkte` | 3NF-Basis; benannter Eigentümer ist von möglichen Rollen mehrerer Mitglieder zu unterscheiden. |
| `application_logs` | `id → Ereignisattribute` | 3NF-Basis; `data_json` ist ein historischer Ereigniswert. |
| `connections` | `id → Verbindungsattribute` | 3NF-Basis; Zugangskonfiguration als JSON, verschlüsseltes Geheimnis separat referenziert. |
| `communication_channels` | `id → Kanalattribute` | 3NF-Basis; Adresse und Provider-Referenz sind derzeit keine deklarierten Kandidatenschlüssel. |
| `inbound_channel_events` | `event_id` und `(team_id, provider, provider_message_id) → Rest` | Historie/JSON; Eingangsereignis und damalige Connector-/Teamzuordnung bleiben unabhängig vom Connectorbestand. Eine Connector-ID allein ist im SQL-Schema kein gesicherter Team-/Provider-Schlüssel. |
| `language_model_connections` | `id → Verbindungsattribute` | 3NF-Basis; Providername bestimmt nicht die frei konfigurierbare API-Adresse. |
| `language_model_defaults` | `team_id → Modellwahl je Verwendungszweck` | 3NF-Basis; referentielle Absicherung und Verhalten bei Modelllöschung separat prüfen. |
| `language_model_secrets` | `secret_ref → verschlüsselter Wert, Zeitpunkt` | 3NF-Basis; Envelope ist ein atomarer verschlüsselter Wert. |
| `language_models` | `id → Modellprofil`; Verbindung bestimmt Team | 3NF-Basis seit `0010`; flexible Fähigkeiten als JSON. Provider-Modell-ID ist ohne Verbindung nicht eindeutig. |
| `model_catalog` | `id → Rest`; Team-ID bestimmt Bereich | Seit `0015` Bereich aus `team_id` abgeleitet, konstante ONNX-Runtime im Adapter. Übersetzungen, Tags, Artefaktreferenz und Vertrag bleiben Aggregate. |
| `runtime_access_credential` | festes `id = 1` → Betreiberzugang | Ein einzelner Konfigurationseintrag; Hash und Salt gehören zur selben Zugangskonfiguration. Keine Zerlegung in weitere Tabellen erforderlich. |
| `runtime_sessions` | `token_hash → Anlage- und Ablaufzeit` | 3NF-Basis. |
| `document_collections` | `(team_id, id)` und `(team_id, display_name) → Rest` | 3NF-Basis; Collection-ID ist teamlokal. |
| `documents` | `(team_id, collection_id, id) → Dokument, Version, Zeitpunkte` | 3NF-Basis der Hülle; Inhalt bleibt frei definierbares JSON. `collection_id` allein bestimmt kein Team. |
| `file_folders` | `id → Rest` | Offen: gültiger Elternordner legt das Team eines Unterordners fest; Wurzeln besitzen keine Eltern-ID. Teamzuordnung und Hierarchie gemeinsam prüfen, einschließlich teamübergreifender Bezüge und Zyklen. |
| `workspace_file_settings` | `team_id → version_limit` | 3NF-Basis. |
| `file_versions` | `id → Versionsattribute` | 3NF-Basis seit `0009`; Team über Datei. Dateiname ist der Name dieser Version, nicht der aktuelle Dateiname. |
| `files` | `id → Dateiattribute` | Versionsmetadaten seit `0009` entdoppelt. Offen: ein zugeordneter Ordner legt das Team fest; Dateien ohne Ordner besitzen eigenes Team. Ablagebeziehung gemeinsam mit Ordnerhierarchie prüfen. |
| `knowledge_notes` | `id → Notizattribute` | Offen: `outgoing_links_json` ist eine vom Client extrahierte Linkprojektion. Abhängigkeit von Inhalt und Wissensbasis, Neuberechnung bei Umbenennung und relationale Linkablage prüfen. |
| `employees` | `id → Mitarbeiterkonfiguration` | 3NF-Basis der Hülle; `skills_json` ist eine konfigurierte Liste externer Fähigkeitsnamen, keine Beziehung auf eine vorhandene SQL-Skilltabelle. |

## Bereits umgesetzt

- `0009`: Dateiversionsmetadaten als maßgebliche Quelle; aktuelle Version
  durch zusammengesetzten Fremdschlüssel ihrer Datei zugeordnet.
- `0010`: Team von Sprachmodellen über Provider-Verbindung abgeleitet.
- `0011`: Benutzerprofile von Teammitgliedschaften getrennt.
- `0012`: Team aus Jobs und Schrittergebnissen entfernt; Zuordnung über Run.
- `0013`: Team aus Auslösern entfernt; Aufgaben-Fremdschlüssel und atomare
  Bereinigung der Webhook-Geheimnisse bei Aufgabenlöschung.
- `0014`: Team und Aufgabe aus Aktivitäten entfernt; Zuordnung über Run.
- `0015`: Modellbereich aus Team-ID abgeleitet; konstante ONNX-Runtime aus
  SQL entfernt und im Adapter ergänzt. Ungültige Eingaben werden vor dem
  Schreiben über den gemeinsamen Katalog-Codec abgelehnt.

## Verbleibende Arbeit

1. Datei-/Ordnerzugehörigkeit einschließlich Wurzeln als einheitliches Modell
   festlegen. `files.folder_id` besitzt noch keinen Fremdschlüssel;
   `file_folders.parent_folder_id` sichert noch nicht dasselbe Team ab.
   Diese Integritätslücken sind zusätzlich zur Normalisierungsfrage zu lösen.
2. Wissenslinks als abgeleitete Projektion mit definiertem Aktualisierungsweg
   oder als eigenständige relationale Beziehung modellieren.
3. Wiederholte Bausteinmetadaten in Aktivitäten und die Herkunftsredundanz
   in Runs auf eine sinnvolle historische Zerlegung prüfen. Historie darf
   weder durch Änderungen aktueller Aufgaben verfälscht noch beim Löschen
   aktueller Aufgaben entfernt werden.
4. Fehlende referentielle Absicherung der Modellvorgaben und Eigentümerbezüge
   getrennt von der Normalform prüfen. Eine zusätzliche Referenz ist nicht
   automatisch ein Normalisierungsschritt.

Die Prüfung aller 28 Tabellen ist damit dokumentiert. Vollständige strenge
3NF des gesamten Speichermodells ist weiterhin nicht bestätigt. Das Ziel
bleibt die Normalisierung stabiler Beziehungen mit ausdrücklich dokumentierten
JSON-Aggregaten und historischen Herkunftsdaten. Firestore wird über seine
separaten Adapter weiter unterstützt.
