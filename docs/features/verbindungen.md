# Feature: Verbindungen und HTTP-Anfrage

Verwandt: [`aufgabe.md`](./aufgabe.md) · [`../node-executor-outputs.md`](../node-executor-outputs.md) ·
[`import-export.md`](./import-export.md) · [`../architecture/betriebsvarianten.md`](../architecture/betriebsvarianten.md)

## Zweck

Aufgaben sollen die HTTP-API externer Systeme nutzen können (Shop, ERP, Mail-Dienst), ohne dass für jedes System neuer
Code entsteht. Dafür gibt es zwei allgemeine Bausteine:

1. **Verbindung** — ein gespeicherter Zugang zu einem System: Basis-URL und Anmeldeart. Das Geheimnis bleibt im Backend.
2. **Baustein „HTTP-Anfrage“** (`httpRequest`) — sendet eine Anfrage, optional über eine Verbindung, und gibt die Antwort
   als typisierte Ausgabewerte weiter.

Systeme mit Besonderheiten (Handshake, Abonnements, eigene Token-Wege) bekommen später einen dünnen Adapter auf dieser
Schicht. Eingehende Webhooks sind der nächste Schritt (siehe [Nicht umgesetzt](#nicht-umgesetzt)).

**Verfügbarkeit:** Standalone (`WorkspaceCapabilities.connections`). In der Cloud gibt es dafür keinen Speicher und keinen
Dienst; dort fehlt der Baustein in der Palette, und eine importierte Aufgabe bricht an dieser Stelle mit einer
verständlichen Meldung ab.

## Verbindungen

| Feld | Bedeutung |
| --- | --- |
| Name | 1–80 Zeichen |
| Basis-URL | `https://…` oder `http://…`, ohne Zugangsdaten, Query oder Anker; ein abschließender `/` entfällt |
| Anmeldeart | siehe unten |
| Geheimnis | API-Key, Token oder Client-Secret (1–4096 Zeichen); Pflicht beim Anlegen |

**Anmeldearten**

- **API-Key im Header:** `<Header-Name>: <Key>`; der Name besteht aus Buchstaben, Ziffern und `-` (z. B. `X-API-Key`).
- **Bearer-Token:** `Authorization: Bearer <Token>`.
- **OAuth client credentials:** Die Runtime holt das Token selbst per POST an die Token-URL
  (`application/x-www-form-urlencoded`: `grant_type`, `client_id`, `client_secret`, optional `scope`) und sendet es als
  Bearer. Das Token liegt im Speicher bis 60 s vor Ablauf (`expires_in`; fehlt es, gilt es 300 s). Gleichzeitige Aufrufe
  teilen sich eine Token-Anfrage. Wird die Verbindung bearbeitet, gilt ein neues Token. Fehlermeldungen nennen Status
  und Grund des Servers, nie das Geheimnis.

Das Geheimnis kommt nie zum Client zurück: Antworten enthalten Name, Basis-URL und Anmeldeart, aber kein Geheimnis. Beim
Bearbeiten lässt ein leeres Geheimnis den gespeicherten Wert unverändert; bei einem Wechsel der Anmeldeart ist ein neues
Pflicht. „Verbindung testen“ (Editor, nur bei gespeicherten Verbindungen) sendet ein GET auf Basis-URL plus optionalem
Pfad und meldet Status und Hinweis (z. B. bei 401: „Prüfe die Zugangsdaten“); der Test prüft den gespeicherten Stand.

**Speicherung:** Tabelle `connections` (Migration `0007_connections.sql`). Das Geheimnis liegt verschlüsselt in der
vorhandenen Tabelle `language_model_secrets` mit `secret_ref = connection/<teamId>/<id>` und derselben Kontextfunktion
wie die Sprachmodelle. Dadurch erfasst die Schlüsselrotation (`local-runtime-secret-rotation-store.ts`) die Geheimnisse
ohne Änderung; der Tabellenname passt nur historisch nicht. Löschen entfernt Verbindung und Geheimnis.

**HTTP-API (lokale Runtime):** `GET/POST /v1/connections`, `PUT/DELETE /v1/connections/:id`,
`POST /v1/connections/:id/test` (antwortet immer mit 200; `ok` und `message` beschreiben das Ergebnis). Thema
`connections` des Realtime-Kanals.

## Baustein „HTTP-Anfrage“

| Einstellung | Bedeutung |
| --- | --- |
| Verbindung | optional; mit Verbindung ist die Adresse ein **Pfad** unter der Basis-URL, ohne die volle URL |
| Methode | GET, POST, PUT, PATCH, DELETE; nur außer GET wird ein Body gesendet |
| Pfad / URL | Template; mit Verbindung relativ (oder eine Adresse derselben Origin) |
| Query, Header | Name-Wert-Listen; Werte sind Templates, Query-Werte werden URL-kodiert |
| Body | `kein`, `JSON` oder `Text`; JSON muss nach dem Einsetzen der Werte gültig sein, sonst bricht der Baustein ab, bevor etwas gesendet wird. Bei JSON ist `Content-Type: application/json` voreingestellt |
| Zeitlimit | 1–120 s, Standard 30 |
| Bei Fehlerstatus abbrechen | Standard an; ausgeschaltet liefert der Baustein `status`/`ok` für Verzweigungen |

**Ausgaben:** `value` (`json`: der geparste JSON-Body, sonst Text, bei leerer Antwort `null`) als `{{antwort}}` bzw.
`{{antwort.feld}}`, dazu die festen Felder `status` (`number`), `ok` (`boolean`, 2xx) und `headers` (`json`, Namen
kleingeschrieben, ohne `set-cookie`), z. B. `{{antwort.status}}`.

**Grenzen:** Antworten höchstens 5 MB (darüber bricht der Baustein ab) und nur Text (UTF-8); Binärantworten sind nicht
vorgesehen. Weiterleitungen werden nur innerhalb derselben Origin verfolgt (höchstens 5; 303 sowie 301/302 nach einem
Nicht-GET werden zu GET ohne Body); eine Weiterleitung zu einem anderen Host kommt als Antwort (3xx) zurück.
Fehlermeldungen nennen nur den Host, nie die vollständige Adresse (die Query kann Token enthalten).

## Sicherheit

- **Zugangsdaten gehen nur an die Origin der Verbindung.** Eine fremde Adresse im Pfad-Feld wird abgelehnt, eine
  Weiterleitung zu einem anderen Host nicht verfolgt. Die Anmeldung der Verbindung überschreibt gleichnamige Header des
  Bausteins.
- **Aktivitätslog:** Das Log schreibt die Konfiguration jedes Bausteins. Für HTTP-Anfragen werden Header-Werte und der
  Body nie geloggt (`•••`), Query-Werte und URL-Parameter nur dann, wenn ihr Name nach Zugangsdaten klingt (`key`, `token`,
  `secret`, `passw…`, `auth…`, `signature`). Aus einer Verbindung kommende Geheimnisse stehen ohnehin nie in der Config,
  nur die `connectionId`.
- **`http://` ist erlaubt** (z. B. Systeme im internen Netz); der Editor warnt, dass Zugangsdaten dann unverschlüsselt
  übertragen werden.
- **Keine Sperre für interne Ziele (bewusste Entscheidung).** Wer Aufgaben bearbeiten kann, kann mit dem Baustein
  interne Adressen der Runtime-Maschine erreichen (`localhost`, Container im Docker-Netz, Metadaten-Endpunkte von
  Cloud-Anbietern). Das ist gewollt, damit Systeme im selben Netz erreichbar sind, bedeutet aber: Das Bearbeiten von
  Aufgaben ist so sensibel wie ein Zugang zum Netz der Runtime. Eine Sperre bzw. Freigabeliste wäre eine einzige Prüfung
  in `ConnectionHttpClient`.
- Selbst eingetippte Header (z. B. ein Token direkt im Baustein) stehen in der Aufgabe im Klartext; für Zugangsdaten
  gehört eine Verbindung her.

## Architektur

| Schicht | Ort |
| --- | --- |
| Verbindung, Eingabeprüfung, Ports | `functions/src/features/connections/domain/` |
| SQLite-Store, Token-Anbieter, Anmeldung, HTTP-Client, Routen | `…/connections/infrastructure/local/` |
| Executor | `task_execution/domain/executors/http-request-node-executor.ts` |
| Dienst für Executoren | `TaskRunServices.outboundHttpClient` (optional, Cloud ohne) |
| Log-Maskierung | `structured-log-format-utils.ts` (`redactedConfig`) |
| Client: Feature | `lib/features/connections/` (Einstellungen-Tab „Verbindungen“) |
| Client: Baustein | `lib/features/task_builder/…/http_request_node_config.dart`, `http_request_widget.dart` |

## Export und Import

Verbindungen und ihre Geheimnisse gehören **nicht** zum Export. Aufgaben verweisen per `connectionId`; auf einem anderen
Gerät zeigt der Baustein „Verbindung nicht gefunden“, bis dort eine Verbindung gewählt ist.

## Nicht umgesetzt

- **Eingehende Webhooks** (Schritt 2): Empfänger-Route in der Runtime mit Token, Signaturprüfung (HMAC) und Handshake-Antworten.
- **Basic Auth** und **delegiertes OAuth** (Nutzer verbindet sein eigenes Konto; braucht eine Redirect-URL der Runtime).
- Ob ein System die OAuth-Token-Anfrage im Format `application/x-www-form-urlencoded` annimmt, ist je System zu prüfen;
  ein JSON-Format ist nicht vorgesehen.
- Seitenweises Abrufen, Wiederholungen und Rate-Limit-Behandlung (derzeit über „Für jedes Element“ zu lösen).
- Der KI-Agent im Aufgabenstudio kennt den Baustein nicht und legt ihn nicht an.
- Keine Vorlagen für bekannte Systeme (z. B. „Shopware: Bestellungen abrufen“).
