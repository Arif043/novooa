# Kommunikationskanal-Datenmodell

> Kommunikationskanäle (SMS, WhatsApp) gehören dem Team, nicht einem Projekt; Auslöser und Aufgaben referenzieren sie nur.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Pfad: `teams/{teamId}/communicationChannels/{channelId}`. Verwaltet werden
Kanäle unter `Einstellungen > Kommunikation`; das UI folgt dem
Superchat-Modell, Provider-Details bleiben Infrastruktur. Ein Team kann
mehrere Kanäle besitzen.

```ts
{
  id: string,
  teamId: string,
  createdByUid: string,
  provider: "twilio",
  kind: "whatsapp",
  label: "Support WhatsApp",
  address: "whatsapp:+491234567890",
  status: "active",            // bis Onboarding-Abschluss: "pendingVerification"
  capabilities: { inbound: true, outbound: true },
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Nutzer:innen verwalten keine Twilio-Zugangsdaten. novooa provisioniert pro
Team einen Twilio-Subaccount und speichert ihn am Team:

```ts
teams/{teamId} { twilioSubaccountSid: string, twilioStatus: "active" | "suspended" }
```

Die Oberfläche zeigt keine Provider-Begriffe wie Twilio, Subaccount oder
Account SID.

WhatsApp-Kanäle sind WhatsApp-Business-Nummern. Eine bestehende
Business-App-Nummer wird über das offizielle Business-Platform-Onboarding
verbunden.

## Siehe auch

- [Eingehende Nachrichten (Inbox)](./eingangs-nachrichten-inbox.md)
- [Twilio-Webhook](./twilio-webhook.md)
- [Kommunikation](../index/kommunikation.md)
