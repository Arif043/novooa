# Runtime-API für Dashboards

Alle Pfade relativ zur Runtime-Adresse, JSON, mit `Authorization: Bearer
<token>`. Aufruf über `WorkspaceApiClient` (`get`, `post`, `put`, `delete`);
Fehler kommen als `WorkspaceHttpException(statusCode, message, errorCode)`
oder `WorkspaceConnectionException`.

## Inhalt

- [Konventionen](#konventionen)
- [Aufgaben](#aufgaben)
- [Lauf starten](#lauf-starten)
- [Läufe](#läufe)
- [Freigaben und Formulare](#freigaben-und-formulare)
- [Aktivitäten](#aktivitäten)
- [Dateien](#dateien)
- [Fehlercodes](#fehlercodes)

## Konventionen

- Listen kommen als `{items: [...]}`.
- Nach jeder Änderung meldet die Runtime ein Echtzeit-Thema mit dem Namen der
  Sammlung ([Echtzeit](echtzeit.md)).
- Fehler: `{error: "<Text>", code?: "<code>"}` oder bei Läufen
  `{failure: {code, message}}`.
- Ohne Lizenz antworten fachliche Endpunkte mit `423`.

## Aufgaben

`GET /v1/tasks` → `{items: TaskDocument[]}`, Thema `tasks`.

```json
{"id": "…", "title": "Rechnung prüfen", "objective": "…", "selectedNodeId": "…",
 "graph": {"nodes": [...], "edges": [...]}}
```

Das Dashboard liest nur `id`, `title`, `objective`. `graph` ist das interne
Modell des Aufgabenstudios; nicht auswerten und nie zurückschreiben
(`PUT`/`DELETE /v1/tasks/:id` gehören nicht ins Dashboard).

## Lauf starten

`POST /v1/task-runs {taskId, context?}` → `202 {runId, taskId, status: "queued"}`.

- `context` ist ein Text, den die Aufgabe als Eingabe erhält (leer erlaubt).
- Ausgeführt wird asynchron; den Fortschritt zeigen Läufe und Aktivitäten.
- `400 {failure: {code: "invalidTaskId" | "invalidRequest"}}`, `500` bei
  Fehlern der Runtime.

```dart
final response = await api.post('/v1/task-runs', {'taskId': id, 'context': input});
final runId = response['runId'] as String;
```

## Läufe

`GET /v1/task-runs` → höchstens 100, zuletzt geänderte zuerst, Thema `task-runs`.

```json
{"runId": "…", "taskId": "…", "taskTitle": "…",
 "status": "queued|running|waitingForApproval|rejected|succeeded|failed",
 "waitingNodeId": "…|null", "finalOutput": "…", "reviewOutput": "…|null",
 "interaction": {…}|null, "error": {…}|null,
 "createdAt": "ISO", "updatedAt": "ISO"}
```

- `finalOutput`: Ergebnis als Text, sobald der Lauf fertig ist.
- `interaction` nur bei `waitingForApproval`:
  - `{kind: "approval", instruction}`
  - `{kind: "dialogInput", instruction, fields: [{name, type, options}]}` mit
    `type` aus `string | number | integer | decimal | selection | boolean | radio | image`

Unbekannte Status als `queued` behandeln (die Vorlage tut das), damit eine
neuere Runtime nichts bricht.

## Freigaben und Formulare

`POST /v1/task-runs/review {runId, decision: "approve"|"reject", output?, formValues?}`
→ `200 {runId, status: "queued"|"rejected"}`.

- Freigabe setzt den Lauf fort, Ablehnung beendet ihn mit `rejected`.
- Bei `dialogInput` gehören alle Felder in `formValues`, typgerecht
  (`integer` als ganze Zahl, `boolean` als `true/false`, `selection`/`radio`
  als eine der `options`). Die Runtime prüft gegen die Definition.
- `image`: Wert ist die `fileId` eines vorher als Team-Datei hochgeladenen
  Bilds (`image/*`); das Feld liefert danach einen `media`-Wert. Quelle und
  Dokumentenscan wählt der Client. Die Vorlage hat noch keinen Upload und
  zeigt für Bildfelder einen Hinweis aufs offizielle Frontend.
- `output` ersetzt optional die Ausgabe des wartenden Bausteins; die Vorlage
  nutzt es nicht.
- `400 {failure: {code: "invalidReviewDecision" | "invalidFormValues" | "invalidRequest"}}`.

## Aktivitäten

`GET /v1/activities` → höchstens 100 Einträge aller Läufe, neueste zuerst,
Thema `task-activities`. Für die Schritte eines Laufs clientseitig nach
`runId` filtern.

```json
{"id": "…", "runId": "…", "taskId": "…", "taskTitle": "…", "target": "…",
 "status": "…", "occurredAt": "ISO", "nodeId": "…|null", "primitive": "…|null",
 "input": "…", "output": "…", "outputs": {"name": {"type": "…", "value": …}},
 "message": "…", "failureCode": "…|null", "failureDetails": {…}|null,
 "origin": {"startedBy": {"uid", "displayName"}|null, "reviewedBy": …, "triggerType": "…|null"}}
```

Rezept „Schritte eines Laufs“: Repository wie `RuntimeRunRepository` mit
`watchWorkspaceChannel('task-activities', load, realtime)`, Domain-Entität
nur mit `occurredAt`, `nodeId`, `status`, `message`, `failureCode`. Anzeigen
als Zeitleiste im Detail eines Laufs.

## Dateien

Werte vom Typ `file`, `media` (Bilder) und `audio` in `outputs` einer
Aktivität tragen eine Referenz
`{fileId, versionId, displayName, contentType, sizeBytes}`. Herunterladen:

`GET /v1/files/:fileId/versions/:versionId/content` → `{contentBase64}`
(`404`, wenn es die Version nicht gibt). Liste aller Dateien:
`GET /v1/files` (Thema `files`).

```dart
Future<Uint8List> download(String fileId, String versionId) async {
  final response = await api.get('/v1/files/$fileId/versions/$versionId/content');
  return base64Decode(response['contentBase64'] as String);
}
```

Speichern bzw. Öffnen ist plattformabhängig (Web: Download über einen
`Blob`-Link, Desktop/Mobil: z. B. `file_selector` oder `share_plus`); dafür
ein eigenes Interface in `domain/` und je Plattform eine Implementierung.

## Fehlercodes

| Status | `code` | Bedeutung |
| --- | --- | --- |
| `401` | `session_required` | Sitzung abgelaufen → Anmeldung ([Authentifizierung](authentifizierung.md)) |
| `401` | `license_rejected` | Lizenz abgelehnt, kein Sitzungsende |
| `403` | `admin_required` | nur für Admins; im Dashboard ein Bug |
| `403` | – | Herkunft nicht erlaubt (Web, CORS) → [Plattformen](plattformen.md) |
| `423` | – | Runtime nicht lizenziert |
| `429` | – | zu viele Anmeldeversuche |
