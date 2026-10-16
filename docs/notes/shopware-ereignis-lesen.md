# Shopware: Ereignis lesen

> `readEvent` gibt Datensatz und Art des Shopware-Ereignisses aus, das den Lauf gestartet hat; ohne Shopware-Auslöser ist er ein Fehler.

Gehört zu: [Integrationen](../index/integrationen.md)

- Braucht **keine Verbindung**.
- `{{ereignis}}`: der Datensatz im einfachen Modell (Bestellung, Kunde,
  Produkt oder Newsletter-Anmeldung, je nach Auslöser); Felder wie
  `{{ereignis.orderNumber}}`, `{{ereignis.email}}`.
- Weitere Werte: `event` (`orderPlaced`, `orderStatus`, `customerRegistered`,
  `stockLow`, `newsletterSubscribed`; Standardname „Ereignisart“), `id`,
  `receivedAt` („Empfangen“).

## Siehe auch

- [Shopware-Auslöser](./shopware-ausloeser.md)
- [Shopware-Bestellmodell](./shopware-bestellmodell.md)
