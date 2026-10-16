# Feature: Kommunikation

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe`](../index/aufgabe.md) · [`zeitplan`](../index/zeitplan.md)

## Zweck

Kommunikation trennt novooa-eigene E-Mails klar von den Postfaechern der
Nutzer:innen. Ein `CommunicationChannel` ist die fachliche Abstraktion für
E-Mail, WhatsApp, SMS und künftige Kanäle. System-E-Mails gehen über SendGrid;
Kundenpostfächer werden über technische Mail-Connectoren angebunden.

## Verantwortlichkeiten

- System-E-Mails von novooa versenden, etwa Benachrichtigungen, Einladungen
  und Marketing-E-Mails.
- Teambezogene Kommunikationskanaele wie E-Mail, WhatsApp und SMS verwalten.
- Kundenpostfaecher mit minimalen, widerrufbaren Berechtigungen verbinden.
- Eingehende Connector-Nachrichten normalisieren und an die Inbox sowie
  Event-Trigger uebergeben.

## System-E-Mail

SendGrid ist ausschliesslich der globale Versanddienst fuer Nachrichten von
novooa. Die Absenderdomain `novooa.de` wird per Domain Authentication
verifiziert. Die Functions erhalten den SendGrid-Key nur als Firebase-Secret
`SENDGRID_API_KEY` und mit der Berechtigung `mail.send`.

System-E-Mails laufen nie ueber ein verbundenes Kundenpostfach. Dadurch kann
ein kompromittierter Versand-Key weder ein Postfach lesen noch Zugang zu
Provider-Einstellungen erlangen.

Nutzer:innen können SendGrid weder konfigurieren noch über Arbeitspläne
verwenden. Ein künftiger `SystemEmailSender` bleibt ein globaler,
backend-interner Dienst.

## Mail-Connectoren

Ein Mail-Connector repräsentiert die technische Anbindung eines konkreten
Kundenpostfachs. Er kapselt Autorisierung, Berechtigungen, Credentials sowie
den Provider-Lebenszyklus und speist daraus einen E-Mail-
`CommunicationChannel`. WhatsApp und SMS haben andere technische
Voraussetzungen, erscheinen fachlich aber als dieselbe Kanalabstraktion.

| Provider | Zugriffsweg | Status |
| --- | --- | --- |
| Gmail / Google Workspace | OAuth und Gmail API | Geplant |
| Microsoft 365 / Outlook.com | OAuth und Microsoft Graph | Implementiert |
| Klassische Mailanbieter | IMAP/SMTP | Geplant |

Connectoren speichern nur verschluesselte, widerrufbare Zugangsdaten. Microsoft
Graph nutzt PKCE, einen serverseitigen OAuth-Callback und die delegierten
Berechtigungen `Mail.Read`, `Mail.Send`, `User.Read` und `offline_access`.
Neue E-Mails treffen per Graph-Webhook ein; ein Scheduler erneuert die
kurzlebigen Subscriptions rechtzeitig.

### Token- und Subscription-Pflege (Microsoft Graph)

Alle Zugriffe auf Microsoft laufen über `MailConnectorTokenService`
(`communication/domain/services/`):

- **Zugriffstoken** werden pro Connector bis kurz vor ihrem Ablauf gemerkt
  (`AccessTokenCache`, pro Funktionsinstanz). Gleichzeitige Aufrufe desselben
  Connectors teilen sich einen Refresh. Lehnt Graph ein Token mit 401 ab, wird
  einmal mit einem frischen wiederholt.
- **Refresh Token:** Microsoft rotiert es bei jedem Refresh; das neue wird
  verschlüsselt gespeichert. Lehnt Microsoft ein Token ab, lädt der Dienst das
  gespeicherte neu — hat eine andere Instanz es inzwischen rotiert, wird einmal
  mit dem neuen wiederholt.
- **Ungültige Anmeldung** (`invalid_grant`, `interaction_required`,
  `consent_required`, `login_required`; z. B. Passwortwechsel, widerrufene
  Einwilligung, gesperrte App, abgelaufenes Token) setzt den Connector auf
  `reauthorizationRequired`. Die App zeigt „Erneute Anmeldung erforderlich" und
  bietet „Postfach neu verbinden" an; Senden meldet, dass das Postfach neu
  verbunden werden muss. Vorübergehende Fehler (Netz, 5xx) ändern den Status
  nicht und werden von der Aufgabenwarteschlange wiederholt.
- **Subscriptions** (2 Tage Laufzeit) verlängert der Scheduler alle 6 Stunden,
  sobald sie innerhalb von 12 Stunden ablaufen. Ist sie abgelaufen, fehlt sie oder
  kennt Graph sie nicht mehr (404), wird eine neue angelegt statt dauerhaft an der
  Verlängerung zu scheitern.
- **Lifecycle-Benachrichtigungen** des Anbieters verarbeitet der Task-Prozessor:
  `reauthorizationRequired` verlängert die Subscription, `subscriptionRemoved`
  legt eine neue an, `missed` wird ignoriert. Verpasste Mails werden nicht
  nachgeholt.
- **Erneutes Verbinden** desselben Postfachs behält die Connector-ID, damit
  Verweise (Kanäle, Auslöser) gültig bleiben; Zugangsdaten und Subscription werden
  ersetzt, der Status ist wieder `active`.

In der Oberfläche erscheinen verbundene E-Mail-Adressen gemeinsam mit
WhatsApp- und SMS-Verbindungen als Kommunikationskanäle. Der technische
Mail-Connector bleibt dabei bewusst im Backend: Er kapselt OAuth,
verschlüsselte Tokens und den Provider-Lebenszyklus, statt diese Details als
Kanal-Konfiguration offenzulegen.

Ein E-Mail-Task verwendet bei einem eingehenden Graph-Event automatisch dessen
Connector, wenn keine `connectorId` am Sende-Baustein gesetzt ist. Unabhängig
gestartete E-Mail-Tasks benötigen eine explizite `connectorId`. So geht jede
Arbeitsplan-E-Mail aus einem verbundenen Kundenpostfach heraus. Der manuelle
Versand verwendet die Callable Function `sendMicrosoftMailConnectorMessage`.

In der lokalen Runtime bleibt der Microsoft-Graph-Connector vollständig im
novooa Cloud Relay: OAuth, Token-Refresh, Versand und Graph-Webhooks werden
dort ausgeführt. Nach einer Firebase-Custom-Token-Anmeldung beobachtet die
Runtime ausschließlich ihr lizenzgebundenes Firestore-Wake-up-Dokument. Bei
einer neuen Revision ruft sie normalisierte E-Mail-Ereignisse aus dem Relay ab
und bestätigt sie nach idempotenter lokaler Verarbeitung.
Nach maximal fünf fehlgeschlagenen Zustellversuchen bewahrt der Relay das
Ereignis in einer lizenzgebundenen Dead-Letter-Queue auf, die die lokale Runtime
anzeigen und gezielt erneut zustellen lassen kann.

### Oberfläche je Variante

Cloud: Der Tab **Kommunikation** unter Einstellungen verwaltet E-Mail, WhatsApp
und SMS. Lokale Runtime: Derselbe Tab zeigt nur die Outlook-Postfächer dieser
Runtime („Postfach verbinden"); siehe
[Mail-Relay und Dead-Letter-Queue](../notes/mail-relay-dead-letter.md).

Aufbau des Tabs (anbieterneutral):

- Kopfzeile mit Titel, Erklärung und der Verbinden-Aktion („Postfach verbinden“
  lokal, „Kanal verbinden“ in der Cloud). Im Leerzustand übernimmt dessen eigene
  Aktion; die Kopfzeile zeigt sie dann nicht doppelt.
- Kanäle erscheinen als Karten im gemeinsamen `ResponsiveCardGrid` (wie
  Aufgaben, Fähigkeiten und Mitarbeiter): Icon, Name, Adresse, Metazeile
  „Anbieter · Richtung“, Status als Punkt plus Text, weitere Aktionen im
  Kanalmenü. Eine abgelaufene Anmeldung zeigt einen Hinweis mit „Neu verbinden“.
- Zustände: Laden, Leer (mit Aktion), Fehler ohne Daten (mit „Erneut
  versuchen“), Fehler mit Daten (Hinweis über den Karten) und Erfolg.
- Die Liste kommt ereignisgesteuert: `watchWorkspaceChannel('mail-connectors')`
  lädt beim Öffnen und danach nur nach einem Signal der Runtime (siehe
  [Mail-Relay und Dead-Letter-Queue](../notes/mail-relay-dead-letter.md)). Die Cloud erhöht
  dafür beim Verbinden oder bei einem Statuswechsel `connectorsRevision` im
  Wake-up-Dokument der Lizenz.
- „Postfach verbinden“ öffnet lokal einen Dialog (`CommunicationMailboxesSheet`,
  Fenster am Desktop, Bottom Sheet auf dem Handy). Seite 1 listet die
  verbundenen Postfächer mit Status (abgelaufene bieten „Neu verbinden“), der
  letzte Eintrag „Weiteres Postfach verbinden“ gleitet zu Seite 2 mit allen
  Anbietern. Ohne Postfach beginnt der Dialog direkt bei den Anbietern. Zurück
  (Pfeil, Fußleiste, System-Zurück) führt zu Seite 1; mit reduzierter Bewegung
  entfällt die Animation. Der Dialog liefert den gewählten Anbieter, die
  Anmeldung startet der Aufrufer. In der Cloud bleibt die Auswahl der
  Kanalart (E-Mail, WhatsApp, SMS) als Aktionsliste.
- Anbieter stehen in `mail_provider_option.dart` (`mailProviderOptions`: Name,
  Beschreibung, Icon, Verbinden-Aktion). Ein neuer Anbieter wie Gmail ist ein
  zusätzlicher Eintrag; er erscheint automatisch auf Seite 2. Anbieternamen für
  die Anzeige liefert `communication_labels.dart`.

## Ereignisse

Ein Connector normalisiert neue E-Mails in ein `EmailReceivedEvent`. Dieses
Ereignis wird in der Team-Inbox gespeichert und kann passende Trigger starten.
Der Baustein `readEmail` liest anschliessend Absender, Betreff und Inhalt aus
dem Run-Event.

```ts
type EmailReceivedEvent = {
  type: "emailReceived",
  connectorId: string,
  senderEmail: string,
  subject: string,
  message: string
}
```

SendGrid-Inbound-Parse ist kein Ersatz fuer einen Connector. Es kann nur neue
E-Mails entgegennehmen, deren separate Empfangs-Subdomain auf SendGrid zeigt;
es kann kein bestehendes Gmail-, Outlook- oder Hetzner-Postfach durchsuchen.

## Sicherheit

- OAuth-Berechtigungen folgen dem Least-Privilege-Prinzip.
- Refresh-Tokens liegen verschluesselt und niemals im Flutter-Client.
- Die Credentials und temporären OAuth-States sind ausschliesslich für
  Cloud Functions lesbar.
- Connectoren sind pro Team isoliert; ein Team kann keine Nachrichten anderer
  Teams lesen oder versenden.
- Ein Trennen widerruft oder loescht die gespeicherten Provider-Zugangsdaten.

## Naechste Schritte

1. Den Flutter-Connector-Dialog und die Connector-Auswahl im Sende-Baustein
   ergänzen.
2. `SystemEmailSender` als separaten backend-internen Dienst bereitstellen.
3. Gmail-Adapter mit OAuth, Empfang und Antwortversand implementieren.
4. IMAP/SMTP als generischen Connector evaluieren.
