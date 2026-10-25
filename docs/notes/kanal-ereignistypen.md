# Normalisierte Kanal-Ereignistypen

> Provider-Adapter übersetzen Rohdaten in novooa-eigene Ereignistypen, bevor Auslöser sie sehen.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Auslöser und Aufgaben kennen nur diese Typen, nie Graph-Formate. Die
Runtime bekommt heute nur `emailReceived` über das Mail-Relay; WhatsApp und
SMS sind als Typen vorgesehen, aber ohne Anbindung.

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

- [E-Mail-Auslöser über Mail-Connector](./email-ausloeser-mail-connector.md)
- [Ereignisziel eines Auslösers](./ausloeser-ereignisziel.md)
