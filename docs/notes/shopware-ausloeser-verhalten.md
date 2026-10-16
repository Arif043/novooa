# Verhalten der Shopware-Auslöser

> Unpassende Ereignisse starten nichts, „Bestand unterschritten“ meldet jede Änderung unter der Grenze, und Fehler beim Nachladen lassen Shopware erneut zustellen.

Gehört zu: [Integrationen](../index/integrationen.md)

- Ereignisname passt nicht zum Auslöser → nichts starten, Antwort 202.
- **Bestand unterschritten** feuert bei jeder Bestandsänderung an oder unter
  der Grenze (Shopware nennt den vorherigen Bestand nicht). Änderungen ohne
  `stock`, Löschungen und Nicht-Produkte werden übersprungen; je Aufruf höchstens
  50 Produkte nachladen.
- Ein Aufruf startet höchstens 10 Läufe.
- Nachladen scheitert (Shop nicht erreichbar, Recht fehlt) → Fehlerantwort,
  damit Shopware es erneut versucht.
- Webhook-Begrenzung: je Auslöser im Schnitt 5 Aufrufe pro Sekunde.

**Nicht geprüft** (nur aus der Shopware-Doku): ob eine App **ohne `<setup>`**
Webhooks sendet, `manifest-2.0.xsd` in 6.6, die Form der Nutzlast (der Code
liest tolerant und braucht nur die Kennung: `order.id`,
`orderTransaction.orderId`, `customer.id`, `newsletterRecipient.id`, bei
`product.written` die Einträge mit `primaryKey` und `updatedFields`) sowie
`newsletter.confirmed` ohne Double-Opt-in. Die Aufrufe sind **nicht
signiert**; eine Signaturprüfung mit App-Geheimnis folgt nach Prüfung am
echten Shop.

Fehlersuche: Webhook-Protokoll in Shopware (Einstellungen → System →
Webhooks) und `bin/console messenger:consume` (Zustellung über die
Warteschlange).

## Siehe auch

- [Shopware-Auslöser](./shopware-ausloeser.md)
- [Shopware-Fehler und Grenzen](./shopware-fehler-und-grenzen.md)
