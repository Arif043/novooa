# Feature: Webhooks (eingehende Aufrufe)

Verwandt: [`verbindungen.md`](./verbindungen.md) · [`zeitplan`](../index/zeitplan.md) · [`aufgabe.md`](./aufgabe.md) ·
[`../node-executor-outputs.md`](../node-executor-outputs.md) · [`../local-runtime.md`](../local-runtime.md)

## Zweck

Externe Systeme (Shopware, Microsoft Graph, beliebige Dienste) sollen eine Aufgabe starten können, indem sie eine Adresse
der Runtime aufrufen. Das ist die eingehende Hälfte der allgemeinen Schicht für externe Systeme; die ausgehende Hälfte
sind [Verbindungen und HTTP-Anfrage](./verbindungen.md).

Ein Webhook ist ein **Auslöser** („Ereignis → Webhook empfangen“) mit einer eigenen Adresse. Die Aufgabe liest den
Inhalt des Aufrufs über den Baustein **„Webhook-Ereignis“** (`readWebhook`).

**Verfügbarkeit:** Standalone (`WorkspaceCapabilities.webhooks`). Die Cloud hat keinen Empfänger; dort fehlen Quelle und
Baustein in der Oberfläche. Die Runtime muss für das externe System erreichbar sein (z. B. auf einer VPS hinter einem
Reverse-Proxy mit `https`).

## Auslöser einrichten

*Zeitplan → Auslöser hinzufügen → Ereignis → Webhook empfangen.*

| Einstellung | Bedeutung |
| --- | --- |
| Signatur prüfen | Ist sie an, prüft die Runtime jede Anfrage per HMAC über den **Rohbody**. Ohne Prüfung genügt die Adresse. |
| Kopfzeile, Verfahren, Darstellung, Präfix | Wo und wie das System die Signatur mitschickt, z. B. `X-Hub-Signature-256`, SHA-256, Hex, Präfix `sha256=`. |
| Geheimnis | Der gemeinsame Schlüssel. Er wird verschlüsselt gespeichert und nie wieder angezeigt. |
| Parameter der Einrichtungsprüfung | Name eines Query-Parameters, den die Runtime unverändert zurückgibt (Microsoft Graph: `validationToken`). Leer: keine Einrichtungsprüfung. |

Nach dem Erstellen zeigt die Karte des Auslösers die **Adresse** (`…/hooks/<Auslöser>/<Token>`) mit Kopierknopf und
„Neue Adresse erzeugen“. Das Token vergibt immer die Runtime (256 Bit zufällig); die bisherige Adresse ist nach dem
Erneuern ungültig.

Die Adresse baut der Client aus der Runtime-Adresse, über die er selbst arbeitet. Ein externes System braucht die
**öffentliche** Adresse; im Web (die Runtime liefert die App aus) ist das dieselbe. Eine abweichende öffentliche Adresse
lässt sich bisher nicht hinterlegen (siehe [Nicht umgesetzt](#nicht-umgesetzt)).

## Aufruf

`POST` oder `PUT` auf `/hooks/:triggerId/:token`. `GET` gilt nur für die Einrichtungsprüfung.

Ablauf in der Runtime (`features/webhooks`):

1. **Lizenz:** ohne aktive Lizenz `423`.
2. **Adresse prüfen:** Auslöser aktiv, Quelle `webhookReceived`, Token gleich (Vergleich über SHA-256 mit
   `timingSafeEqual`). Unbekannte Kennung, falsches Token und deaktivierter Auslöser sehen **gleich** aus: `404`.
3. **Fehlversuche begrenzen:** Jeder fehlgeschlagene Versuch kostet einen Eimer (30, 1 pro Sekunde); ist er leer, folgt
   `429` mit `Retry-After`. Gültige Aufrufe belastet das nicht.
4. **Auslöser begrenzen:** je Auslöser im Schnitt 5 Aufrufe pro Sekunde, Stöße bis 20 (`429`).
5. **Einrichtungsprüfung:** Ist der Parameter konfiguriert und in der Query vorhanden, antwortet die Runtime `200`
   (`text/plain`, `X-Content-Type-Options: nosniff`) mit dem Wert, höchstens 2048 Zeichen, und startet **keinen** Lauf.
6. **Signatur:** bei aktiver Prüfung über die Rohbytes; fehlt Kopfzeile oder Geheimnis oder stimmt sie nicht: `401`.
7. **Lauf starten:** über denselben Weg wie alle Event-Trigger (`startEventTriggerRun`), Antwort `202` ohne Inhalt.
   Die Antwort kommt sofort; die Ausführung läuft über den Worker.

Fehlerantworten sind kurz und einheitlich (`{"error": …}`), damit sie nichts über vorhandene Auslöser verraten. Zu große
Anfragen (über 1 MiB) ergeben `413`.

### Ereignis

Der Lauf bekommt `input.event`:

```json
{
  "type": "webhookReceived", "method": "POST",
  "query": {"a": "1"}, "headers": {"content-type": "application/json"},
  "body": {"bestellung": 42}, "receivedAt": "2026-10-05T10:00:00.000Z"
}
```

- `body`: JSON und `application/x-www-form-urlencoded` als Objekt, alles andere (und ungültiges JSON) als Text.
- `headers`: **ohne** `authorization`, `proxy-authorization`, `cookie`, `set-cookie` und die Signatur-Kopfzeile.
- Der lesbare Kontext des Laufs („Webhook empfangen, Methode, Inhaltstyp, Größe“) enthält weder Token noch Inhalt.

## Baustein „Webhook-Ereignis“

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{ereignis}}` / `{{ereignis.feld}}` | `json` (bei Text: `string`) | Inhalt des Aufrufs; Felder eines JSON-Objekts direkt als `{{ereignis.bestellung}}` |
| `{{Methode}}` (`method`) | `string` | `POST` oder `PUT` |
| `{{Abfrage}}` (`query`) | `json` | Query-Parameter |
| `{{Kopfzeilen}}` (`headers`) | `json` | Kopfzeilen (siehe oben) |
| `{{Empfangen}}` (`receivedAt`) | `datetime` | Zeitpunkt des Empfangs |

Ein Lauf, der nicht durch einen Webhook gestartet wurde (z. B. manuell), bricht mit „Dieser Lauf wurde nicht durch einen
Webhook gestartet“ ab.

## Architektur

- **Eigenes Routen-Plugin neben der API** (`webhookRoutes`, registriert in `runtimeRoutes` neben `localRuntimeApi`): Die
  API-Hooks verlangen Sitzung und Lizenz auf allen Routen; ein externes System hat keine Sitzung. Das Plugin hat eine
  **eigene Lizenzprüfung**, eigenen Rohbody-Parser (alle Inhaltstypen als `Buffer`, auch JSON) und eigenen Fehler-Handler.
  Es ist im Zugriffs-Katalog von [`../local-runtime.md`](../local-runtime.md) als Ausnahme von der Sitzungspflicht
  geführt. Der verschlüsselte Tunnel (`/v1/secure/…`) leitet `/hooks/…` nicht weiter.
- **Domäne** (`features/webhooks/domain`): `ReceiveWebhook` (Ablauf), `verify-webhook-signature` (reine Funktion),
  `webhook-event` (Ereignis, Kopfzeilenfilter, Body-Auswertung). Der Zugang zum Arbeitsbereich läuft über
  `workspaceContext.webhooks`, wie bei `fileEvents`.
- **Konfiguration** in `scheduling`: `EventTriggerConfig.webhook` (`token`, `verification`, `validationParameter`) in
  `task_triggers.event_config_json`; die Registry der Ereignisquellen (`EventTriggerSourceRegistry`) vergibt das Token
  serverseitig (`prepare`).
- **Auslöser anderer Quellen** (`WebhookInterpreter`, `webhooks/domain/entities/webhook-interpreter.ts`): Eine Quelle mit
  `usesWebhook` bekommt Token und Adresse wie `webhookReceived`; nach Token- und Signaturprüfung wertet ihr Interpreter den
  Aufruf aus und liefert null bis zehn Läufe (Kontexttext, Ereignis). Plugins bringen Quelle und Interpreter mit
  (`IntegrationPlugin.eventTriggers`; Beispiel: [Shopware](./shopware.md)). Quellspezifische Einstellungen stehen in
  `EventTriggerConfig.params`, die das Plugin selbst prüft (`problem`).
- **Geheimnis** der Signaturprüfung: verschlüsselt in `language_model_secrets` mit `secret_ref = webhook/<team>/<trigger>`
  (derselbe Speicher und dieselbe Schlüsselrotation wie bei Verbindungen). Es steht nie in der Konfiguration und wird nie
  ausgeliefert; beim Löschen des Auslösers wird es mitgelöscht.
- **Routen:** `POST /v1/task-triggers` (legt Token und Geheimnis an), `POST /v1/task-triggers/:id/webhook-token`
  (Token erneuern).
- **Begrenzung:** Token-Bucket-Algorithmus des Skills-Relays, im Speicher (`InMemoryBucketStateStore`); ein Neustart oder
  Arbeitsbereichswechsel setzt die Eimer zurück.

## Sicherheit und Grenzen

- **Öffentlicher Endpunkt.** Geschützt wird er durch das Token (256 Bit) und die Begrenzungen. Die Adresse steht in
  Zugriffsprotokollen eines Reverse-Proxys; deshalb **Signaturprüfung einschalten**, wo das System sie anbietet.
- **Keine IP-Begrenzung.** Hinter einem Reverse-Proxy sähen alle Aufrufer gleich aus (`trustProxy` ist nicht gesetzt);
  deshalb gibt es einen gemeinsamen Eimer für Fehlversuche statt eines je Adresse.
- **Keine Wiederholungs- und Duplikaterkennung.** Wiederholt ein Absender einen Aufruf (oder spielt jemand einen
  abgefangenen mit gültiger Signatur ab), entsteht ein weiterer Lauf. Eine Zeitstempelprüfung gibt es nicht.
- **Unvertrauenswürdige Eingabe.** Der Inhalt eines Webhooks stammt von außen. Fließt er in einen Prompt, ist
  Prompt-Injection möglich; es gibt dagegen keine technische Maßnahme.
- Der Inhalt wird mit dem Lauf gespeichert (bis 1 MiB) und taucht im Aktivitätsprotokoll auf.
- Ein Auslöser läuft nur, solange die Runtime läuft und die Lizenz aktiv ist; verpasste Aufrufe holt niemand nach.

## Nicht umgesetzt

- Verwaltung von Abonnements bei Absendern (z. B. Microsoft-Graph-Subscriptions anlegen und verlängern).
- Adapter für bestimmte Systeme; die Einrichtungsprüfung und HMAC sind allgemein gehalten.
- Eine konfigurierbare öffentliche Basis-Adresse (z. B. `NOVOOA_PUBLIC_URL`) für die angezeigte Adresse.
- Ändern des Geheimnisses oder der Prüfung eines vorhandenen Auslösers: Auslöser löschen und neu anlegen.
- Idempotenz, Zeitstempelprüfung, andere Signaturarten (nur HMAC), Filter auf den Inhalt.
- Der KI-Agent im Aufgabenstudio kennt den Baustein nicht.
