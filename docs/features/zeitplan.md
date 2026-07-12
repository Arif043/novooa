# Feature: Zeitplan

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`aktivitaeten.md`](./aktivitaeten.md)

## Zweck

Zeit- und event-gesteuerte Auslöser für Aufgaben. Nutzer:innen konfigurieren
hier, **wann** eine Aufgabe läuft, ohne den Workflow selbst zu bearbeiten.

Umgesetzt sind zeitbasierte Trigger, die UI-/Persistenz-Grundlage für
Event-Trigger sowie der Twilio-Eingang für „WhatsApp-Nachricht“. Weitere
Provider wie E-Mail, Datei-Events und generische Webhooks nutzen später
dieselbe Event-Trigger-Struktur.

## Datenmodell

Trigger liegen team-scoped unter:

```text
teams/{teamId}/taskTriggers/{triggerId}
```

Dokument:

```ts
{
  id: string,
  teamId: string,
  createdByUid: string,
  taskId: string,
  taskTitle: string,
  type: "schedule" | "event",
  enabled: boolean,
  config?: {
    kind: "once" | "daily" | "weekly",
    timezone: "Europe/Berlin",
    runAt?: Timestamp,
    timeOfDay?: "09:00",
    weekdays?: number[],
    slots?: Array<{
      weekday: number,
      timeOfDay: "09:00"
    }>
  },
  eventConfig?: {
    source: "emailReceived" | "whatsappMessageReceived" | "fileCreated" | "webhookReceived",
    filter: string,
    channelId?: string
  },
  policy: {
    ifRunning: "skipIfRunning" | "startParallel"
  },
  nextRunAt?: Timestamp,
  lastRunAt?: Timestamp,
  lastRunId?: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

`nextRunAt` ist für Zeitplan-Trigger bewusst materialisiert, damit der
Backend-Worker fällige Trigger effizient per Query finden kann. Event-Trigger
haben `nextRunAt = null` und warten auf externe Ereignisse.

Kommunikationskanäle liegen team-scoped unter:

```text
teams/{teamId}/communicationChannels/{channelId}
```

Die Verwaltung der Kanäle liegt in der UI unter
`Einstellungen > Kommunikation`. Trigger referenzieren diese Kanäle nur.

Minimal erwartetes WhatsApp-Dokument:

```ts
{
  id: string,
  teamId: string,
  createdByUid: string,
  provider: "twilio",
  kind: "whatsapp",
  label: "Support WhatsApp",
  address: "whatsapp:+491234567890",
  status: "active",
  capabilities: {
    inbound: true,
    outbound: true
  },
  accountSid: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Ein Team kann mehrere Kanäle besitzen. Kanäle gehören bewusst nicht zu
einzelnen Projekten; Aufgaben und Trigger referenzieren bei Bedarf einen
Team-Kanal.

Eingehende Nachrichten werden unter dem Team-Inbox-Pfad gespeichert:

```text
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}/messages/{messageSid}
```

## UI

Die Seite `Zeitplan` zeigt Trigger als Kacheln. Jede Kachel enthält:

- Aufgabe
- Trigger-Regel
- Aktiv/Pausiert-Schalter
- nächste Ausführung
- Löschen-Aktion

Der Dialog „Trigger hinzufügen“ bietet:

- Ereignis: E-Mail, WhatsApp, Datei erstellt, Webhook
- einmalig
- täglich
- wöchentlich mit frei wählbaren Wochenzeitpunkten wie „Mo 09:00“,
  „Mi 14:30“ oder „Fr 08:15“

Cron-Ausdrücke werden nicht direkt im UI eingegeben. Die UI erzeugt einfache
strukturierte Konfigurationen, aus denen Backend und Client `nextRunAt`
berechnen.

## Backend

`runDueTaskTriggersWorker` läuft jede Minute und verarbeitet nur fällige
Zeitplan-Trigger über:

```text
collectionGroup("taskTriggers")
  where enabled == true
  where nextRunAt <= now
```

Für jeden fälligen Zeitplan-Trigger:

1. Aufgabe aus `teams/{teamId}/tasks/{taskId}` laden.
2. Bei `policy.ifRunning == "skipIfRunning"` aktive Runs derselben Aufgabe
   überspringen.
3. `taskRuns/{runId}` über dieselbe Queue-Struktur erzeugen wie manuelle Runs.
4. `lastRunAt`, `lastRunId` und `nextRunAt` am Trigger aktualisieren.
5. Einmalige Trigger nach Ausführung deaktivieren.

Der erzeugte `taskRun` enthält zusätzlich:

```ts
{
  source: "trigger",
  triggerId: string,
  triggerType: "schedule" | "event"
}
```

### Twilio WhatsApp

Die Function `twilioWebhook` nimmt Twilio Messaging-Webhooks entgegen. Die
Webhook-URL enthält die Zuordnung zu Team und Kommunikationskanal:

```text
https://<region>-<project>.cloudfunctions.net/twilioWebhook?teamId=<teamId>&channelId=<channelId>
```

Die Function:

1. akzeptiert `POST` mit `application/x-www-form-urlencoded`,
2. prüft `X-Twilio-Signature` gegen `TWILIO_AUTH_TOKEN`,
3. validiert den Kommunikationskanal,
4. speichert die Nachricht idempotent per Twilio-`MessageSid`,
5. startet passende aktive Event-Trigger mit
   `eventConfig.source == "whatsappMessageReceived"`. Wenn ein Trigger
   `eventConfig.channelId` setzt, wird nur dieser Team-Kanal berücksichtigt.

Im Functions Emulator wird eine fehlende `TWILIO_AUTH_TOKEN`-Secret für lokale
Tests toleriert. In Production ist `TWILIO_AUTH_TOKEN` erforderlich.

Lokal kann der Worker gegen den Functions Emulator manuell ausgelöst werden:

```bash
npm --prefix functions run schedule:run:local
```

Der Emulator exportiert scheduled/background Functions lokal mit `-0`-Suffix,
daher ruft der Script `runDueTaskTriggersWorker-0` auf.

## Firestore

Security Rules erlauben Team-Mitgliedern Lesen, Erstellen, Aktualisieren und
Löschen von `taskTriggers`. Die Rules validieren Zeitplan-Trigger über
`config` und Event-Trigger über `eventConfig`, jeweils inklusive `policy`,
Team-Scope und existierender Aufgabe.

Für die Worker-Query ist ein Composite Index in `firestore.indexes.json`
definiert:

```text
collectionGroup: taskTriggers
enabled ASC, nextRunAt ASC
```

## Nächste Schritte

- Bearbeiten-Dialog für bestehende Trigger ergänzen.
- Event-Trigger `fileCreated` auf Storage-/Firestore-Dateiversionen ausführen.
- Verbindungs-UI für Twilio-Accounts und Telefonnummern ergänzen.
- E-Mail-Trigger per Provider-Webhook an `taskRuns` anbinden.
- Team-Rollen später auf Trigger-Verwaltung anwenden.
