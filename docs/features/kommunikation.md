# Feature: Kommunikation

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) · [`zeitplan.md`](./zeitplan.md)

## Zweck

Kommunikation trennt novooa-eigene E-Mails klar von den Postfaechern der
Nutzer:innen. System-E-Mails gehen ueber SendGrid. Mail-Connectoren verbinden
ein konkretes Kundenpostfach und stellen dessen Nachrichten fuer Aufgaben und
Trigger bereit.

## Verantwortlichkeiten

- System-E-Mails von novooa versenden, etwa Benachrichtigungen, Einladungen
  und Marketing-E-Mails.
- Teambezogene Nachrichtenkanaele wie WhatsApp und SMS verwalten.
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

Ein Mail-Connector repraesentiert ein konkretes Kundenpostfach. Er ist ein
Teilmodul von Kommunikation und kapselt Autorisierung, Berechtigungen,
Credentials sowie den Provider-Lebenszyklus. Er wird nicht als einfacher,
frei konfigurierbarer `communicationChannel` gespeichert.

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

Ein E-Mail-Task verwendet bei einem eingehenden Graph-Event automatisch dessen
Connector, wenn keine `connectorId` am Sende-Baustein gesetzt ist. Unabhängig
gestartete E-Mail-Tasks benötigen eine explizite `connectorId`. So geht jede
Arbeitsplan-E-Mail aus einem verbundenen Kundenpostfach heraus. Der manuelle
Versand verwendet die Callable Function `sendMicrosoftMailConnectorMessage`.

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
