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
    source: "emailReceived" | "smsMessageReceived" | "whatsappMessageReceived"
      | "fileCreated" | "fileVersionCreated" | "fileDeleted" | "webhookReceived"
      | "plugin",                                                    // siehe plugins.md
    target: { kind: "any" }                                          // überall (Standard)
      | { kind: "folder", id: string, includeSubfolders: boolean }   // Datei-Ereignisse
      | { kind: "file", id: string }                                 // Datei-Ereignisse
      | { kind: "channel", id: string }                              // SMS, WhatsApp
      | { kind: "connector", id: string },                           // E-Mail
    fileKinds: Array<"text" | "image" | "video" | "audio" | "pdf" | "spreadsheet" | "other">,
    filter: string,
    plugin?: {                                                       // nur bei source "plugin"
      pluginId: string, type: string, label: string,
      settings: Record<string, string | number | boolean>
    }
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

Alle Ereignisquellen teilen dieselbe Zielstruktur (`target`): Datei-Ereignisse
zielen auf ein Verzeichnis (optional samt Unterordnern) oder eine einzelne
Datei, Nachrichten auf einen Kanal bzw. Mail-Connector. Fehlt `target` oder ist
es unvollständig, gilt „überall". `fileKinds` schränkt Datei-Ereignisse auf
Kategorien ein (leer = alle), `filter` ist ein optionaler Textfilter — bei
Nachrichten gegen den Nachrichtentext, bei Dateien gegen den Dateinamen.
Das Matching liegt als reine Funktion in
`scheduling/domain/usecases/event-trigger-matching.ts`.

`nextRunAt` ist für Zeitplan-Trigger bewusst materialisiert, damit der
Backend-Worker fällige Trigger effizient per Query finden kann. Event-Trigger
haben `nextRunAt = null` und warten auf externe Ereignisse.

Kommunikationskanäle liegen team-scoped unter:

```text
teams/{teamId}/communicationChannels/{channelId}
```

Die Verwaltung der Kanäle liegt in der UI unter
`Einstellungen > Kommunikation`. Trigger referenzieren diese Kanäle nur.
Nutzer verwalten keine Twilio-Credentials. novooa provisioniert intern einen
Twilio-Subaccount pro Team und speichert dessen SID am Team-Dokument:

```ts
teams/{teamId} {
  twilioSubaccountSid: string,
  twilioStatus: "active" | "suspended"
}
```

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
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Ein Team kann mehrere Kanaele besitzen. Kanaele gehoeren bewusst nicht zu
einzelnen Projekten; Aufgaben und Trigger referenzieren bei Bedarf einen
Team-Kanal. Die UI folgt dem Superchat-Modell fuer WhatsApp und SMS; Provider-
Details bleiben Infrastruktur.

E-Mail-Trigger referenzieren einen separaten Mail-Connector statt
eines SendGrid-Kanals. SendGrid bleibt auf novooa-eigene ausgehende System-
E-Mails beschraenkt und erzeugt keine Kundenpostfach-Ereignisse. Microsoft
Graph liefert neue E-Mails bereits über seinen Connector; Gmail folgt später.
Bei `eventConfig.source == "emailReceived"` wird `connectorId` statt
`channelId` verwendet.
WhatsApp-Verbindungen beziehen sich auf WhatsApp-Business-Nummern. Eine
bestehende WhatsApp-Business-App-Nummer wird über das offizielle
Business-Platform-Onboarding verbunden und bleibt bis zum Abschluss als
`pendingVerification` gespeichert.

Eingehende Nachrichten werden unter dem Team-Inbox-Pfad gespeichert:

```text
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}/messages/{messageSid}
```

## UI

Die Seite `Zeitplan` verwendet das Designsystem „Luminous Precision“ mit
Inter-Typografie, zurückhaltenden Orange-Akzenten und iOS-artigen Steuerelementen.
Eine scrollbare Liste mit höhenflexiblen Karten ersetzt das starre Kachelraster.
Der Kopfbereich zeigt die Anzahl aktiver und pausierter Auslöser. Jede Karte enthält:

- Aufgabe
- Trigger-Regel
- Aktiv/Pausiert-Schalter
- nächste Ausführung
- Löschen-Aktion mit Bestätigung (die Aufgabe bleibt erhalten)

Der Dialog „Auslöser hinzufügen“ bietet gruppierte Einstellungen, native
Datums-/Zeitpicker und folgende Optionen:

- Ereignis: E-Mail, SMS, WhatsApp, Datei erstellt, Neue Dateiversion, Datei
  gelöscht, Webhook. Zu jedem Ereignis gibt es ein Feld für das Ziel
  („Wo?", „Welcher Kanal?", „Welches Postfach?", Standard: Überall), das ein
  Auswahl-Sheet öffnet:
  - Datei-Ereignisse: Verzeichnisbaum (mit Schalter „Unterordner einbeziehen")
    oder einzelne Datei mit Suche. Darunter Chips für Dateitypen (Text, Bilder,
    Video, Audio, PDF, Tabellen, Sonstige; ohne Auswahl: alle). Bei einer
    einzelnen Datei entfallen die Dateitypen.
  - SMS/WhatsApp: aktive Kanäle des passenden Typs. E-Mail: verbundene
    Postfächer. In Betriebsvarianten ohne Kommunikationskanäle bleibt „Überall".
  - Der Textfilter liegt eingeklappt unter „Weitere Optionen".
  Die Trigger-Karte fasst das zusammen, z. B. „Datei erstellt · Berichte / 2026
  (mit Unterordnern) · Bilder". Der Name des Ziels wird als `label` mitgespeichert
  und dient nur der Anzeige.
- einmalig
- täglich
- wöchentlich mit frei wählbaren Wochenzeitpunkten wie „Mo 09:00“,
  „Mi 14:30“ oder „Fr 08:15“

Die Aufgabe wählt man über ein Dropdown. Datum und Uhrzeit
folgen der Sheet-Regel der App (`showAdaptiveSheet`): Auf dem Handy bzw. in
Fenstern unter 600 px öffnet sich ein Bottom Sheet mit Drehrad („Abbrechen" /
„Fertig"), am Desktop (macOS, Windows, Linux ab 600 px) der übliche
Kalender- bzw. Uhrzeit-Dialog von Material. Die App ist dafür auf Deutsch
lokalisiert (`flutter_localizations`).

Auf kleinen Displays und bei großer Systemschrift werden Segmentauswahlen
durch beschriftete Auswahlfelder ersetzt. Der Dialog bleibt scrollbar.
Speichern verhindert doppelte Übermittlung und erhält bei Fehlern die Eingaben.
Hell- und Dunkelmodus, Leerzustände und Lade-/Fehlerrückmeldungen sind berücksichtigt.

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

### Datei-Ereignisse

Der Dateispeicher meldet jede Schreib- und Löschoperation als `FileEvent`
(`fileCreated`, `fileVersionCreated`, `fileDeleted`). Der Use Case
`DispatchFileEvent` lädt die aktiven Event-Trigger, löst die Verzeichniskette
der Datei auf und startet jede Aufgabe, deren Quelle, Ziel, Dateikategorie und
Filter passen. Die Aufgabe erhält das Ereignis als `input.event`. Fehler eines
Triggers stoppen weder die Dateioperation noch andere Trigger.

Aktuell ist das nur in der lokalen Runtime verdrahtet (Upload, Baustein
„Datei schreiben" und Löschen).

### Schleifenschutz

Aufgaben können sich über Datei-Trigger gegenseitig oder selbst starten. Der
Schutz hat zwei Ebenen, analog zu Vermeidung und Erkennung beim Deadlock:

**Laufzeit (streng).** Jeder Lauf trägt seine Ursachenkette (`triggerChain`,
die IDs aller Event-Trigger, die ihn mittelbar ausgelöst haben) im Lauf-Input.
`TriggerChainTeamFileStore` (Decorator) hängt sie an jede Schreiboperation des
Laufs; sie steht dann im `FileEvent`. `DispatchFileEvent` startet einen Trigger
nicht, wenn seine ID schon in der Kette steht — schon die erste Wiederholung
wird verhindert. Das Ereignis erscheint als „Schleife verhindert" im Anwendungs-
protokoll. Das gilt für alle Datei-Quellen, auch für Läufe, die ein Nachrichten-
Trigger gestartet hat.

**Entwurfszeit (statisch).** `findTriggerCycles` bildet den Graphen nach dem
Muster des Betriebsmittelbelegungsgraphen: Aufgabe → Trigger („schreibt etwas,
das den Trigger auslöst", Matrix `W`) und Trigger → Aufgabe („startet", Matrix
`T`). Die Reduktion auf einen Graphen über Aufgaben ist das Boolesche
Matrixprodukt `E = W ⊗ T`; ein Zyklus liegt vor, wo die transitive Hülle `E⁺`
(Warshall) auf der Diagonale eine 1 hat. Die Schreibstellen einer Aufgabe
(`fileWriteSitesOf`: Datei schreiben, Bild-Prompt, Sprachausgabe — auch in
Verzweigungen und Schleifen) werden gegen Quelle, Ziel, Dateityp und Filter der
Trigger geprüft (`writeMatch`). Zur Entwurfszeit sind Laufzeitwerte unbekannt,
deshalb kennt jede Kante die Sicherheit `certain` oder `possible`.

- **Selbstschleife mit sicherer Kante:** wird hart abgelehnt (HTTP 400) — beim
  Anlegen und Aktivieren eines Triggers und beim Speichern einer Aufgabe.
- **Alle anderen Zyklen:** nur Warnung. Beim Anlegen eines Triggers liefert
  `POST /v1/task-triggers/analysis` Selbstschleife (`blocked`) und Warnungen
  vorab; der Dialog fordert dann eine bewusste Bestätigung. Beim Speichern einer
  Aufgabe steht die Warnung in `warnings` der Antwort und erscheint im
  Task-Builder als Hinweis; eine Ablehnung als „Nicht gespeichert: …".

Die Prüfung ist eine Überapproximation: Sie kennt keine Laufzeitwerte und keine
Verzweigungsentscheidungen. Deshalb ist nur die Selbstschleife mit sicherer
Kante ein Fehler; ein bedingter Zweig, der nie läuft, lässt sich statisch nicht
vom Normalfall unterscheiden. Die Laufzeitebene fängt alles ab, was die
statische übersieht.

### Channel-Nachrichten

Die Function `twilioWebhook` nimmt Twilio Messaging-Webhooks entgegen. Die
Webhook-URL enthält die Zuordnung zu Team und Kommunikationskanal:

```text
https://twiliowebhook-ilhamoy3ua-ey.a.run.app?teamId=<teamId>&channelId=<channelId>
```

Alle Cloud Functions werden in Frankfurt (`europe-west3`) deployed. Für Twilio
muss exakt die deployte HTTPS-URL inklusive Query-Parametern in der Konsole als
`HTTP POST`-Webhook hinterlegt werden.
WhatsApp-Adressen werden im Webhook normalisiert: Twilios `whatsapp:+...` wird
intern als `+...` gespeichert und gegen den Kommunikationskanal verglichen.

Die Function:

1. akzeptiert `POST` mit `application/x-www-form-urlencoded`,
2. prüft `X-Twilio-Signature` gegen `TWILIO_AUTH_TOKEN`,
3. validiert den Kommunikationskanal,
4. speichert die Nachricht idempotent per Twilio-`MessageSid`,
5. startet passende aktive Event-Trigger. SMS verwendet
   `eventConfig.source == "smsMessageReceived"`, WhatsApp verwendet
   `eventConfig.source == "whatsappMessageReceived"`. Wenn ein Trigger
   `eventConfig.channelId` setzt, wird nur dieser Team-Kanal berücksichtigt.
   Mail-Connectoren erhalten einen eigenen Provider-Adapter und filtern
   E-Mail-Trigger ueber `eventConfig.connectorId`.

Provider-Adapter normalisieren Rohdaten vor dem Dispatch in konkrete
novooa-Eventtypen:

```ts
type EmailReceivedEvent = {
  type: "emailReceived",
  connectorId: string,
  senderEmail: string,
  subject: string,
  message: string
}

type WhatsappMessageReceivedEvent = {
  type: "whatsappMessageReceived",
  senderPhoneNumber: string,
  message: string
}

type SmsMessageReceivedEvent = {
  type: "smsMessageReceived",
  senderPhoneNumber: string,
  message: string
}
```

Für lokale Tests ohne Provider-Guthaben gibt es die Callable Function
`dispatchFakeChannelMessage`. Sie ist authentifiziert, nutzt den persönlichen
Team-Kontext des angemeldeten Nutzers, lädt den angegebenen
`communicationChannels/{channelId}`-Datensatz, schreibt eine Fake-Inbound-
Nachricht in die Inbox und dispatcht danach dieselben Channel-Trigger wie ein
echter Twilio-Webhook. In der UI ist sie über `Einstellungen > Kommunikation`
pro Kanal als Testnachricht erreichbar. Ein entsprechender Connector-Test für
E-Mail wird mit den Mail-Connectoren ergänzt.

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
- Nummern-/WhatsApp-Provisionierung innerhalb des Team-Subaccounts ergänzen.
- E-Mail-Connectoren und ihre Provider-Ereignisse an `taskRuns` anbinden.
- Team-Rollen später auf Trigger-Verwaltung anwenden.
