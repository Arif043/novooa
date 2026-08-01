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

Die bestehende Implementierung verwendet SendGrid noch ueber einen aktiven
team-scoped E-Mail-Kanal. Sie wird auf einen globalen `SystemEmailSender`
migriert; Nutzer:innen konfigurieren dafuer weder eine SendGrid-Adresse noch
einen SendGrid-Key.

## Mail-Connectoren

Ein Mail-Connector repraesentiert ein konkretes Kundenpostfach. Er wird
team-scoped verwaltet, ist aber kein `communicationChannel`, weil seine
Berechtigungen und sein Lebenszyklus wesentlich weiter reichen als bei einer
Telefonnummer.

| Provider | Zugriffsweg | Status |
| --- | --- | --- |
| Gmail / Google Workspace | OAuth und Gmail API | Geplant |
| Microsoft 365 / Outlook | OAuth und Microsoft Graph | Geplant |
| Klassische Mailanbieter | IMAP/SMTP | Geplant |

Connectoren speichern nur verschluesselte, widerrufbare Zugangsdaten. Die UI
zeigt die genaue Adresse, die gewaehrten Faehigkeiten und eine Aktion zum
Trennen des Postfachs. Das Senden einer Antwort erfolgt stets ueber denselben
Connector, aus dem die Nachricht stammt.

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
- Connectoren sind pro Team isoliert; ein Team kann keine Nachrichten anderer
  Teams lesen oder versenden.
- Ein Trennen widerruft oder loescht die gespeicherten Provider-Zugangsdaten.

## Naechste Schritte

1. `SystemEmailSender` aus dem team-scoped SendGrid-Kanal herausloesen.
2. Mail-Connector-Aggregat mit Lifecycle und verschluesselter Credential-Store
   definieren.
3. Gmail- und Microsoft-Adapter mit OAuth, Empfang und Antwortversand
   implementieren.
4. IMAP/SMTP als generischen Connector evaluieren.
