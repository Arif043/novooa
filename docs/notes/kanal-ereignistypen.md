# Normalisierte Kanal-Ereignistypen

> Provider-Adapter übersetzen Rohdaten in novooa-eigene Ereignistypen, bevor Auslöser sie sehen.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Auslöser und Aufgaben kennen nur diese Typen, nie Twilio- oder
Graph-Formate:

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

## Siehe auch

- [Twilio-Webhook](./twilio-webhook.md)
- [E-Mail-Auslöser über Mail-Connector](./email-ausloeser-mail-connector.md)
- [Ereignisziel eines Auslösers](./ausloeser-ereignisziel.md)
