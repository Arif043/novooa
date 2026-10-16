# Shopware-Auslöser

> Shopware meldet Ereignisse über eine kleine, je Auslöser erzeugte Shopware-App an den Webhook-Empfänger; novooa lädt den Datensatz nach und startet die Aufgabe.

Gehört zu: [Integrationen](../index/integrationen.md)

Quelle **„Shopware-Ereignis“** unter Zeitplan → Auslöser → Ereignis
(`eventConfig.params`: Ereignis, Verbindung, Status, Bestandsgrenze).

| Ereignis | Shopware-Ereignis | Einstellungen |
| --- | --- | --- |
| Neue Bestellung | `checkout.order.placed` | – |
| Bestellstatus erreicht | `state_enter.<order\|order_transaction\|order_delivery>.state.<status>` | Bereich, Zielstatus |
| Neuer Kunde | `checkout.customer.register` | – |
| Bestand unterschritten | `product.written` | Bestand höchstens N |
| Newsletter-Anmeldung | `newsletter.confirmed` oder `newsletter.register` | erst nach Bestätigung (Standard an) |

**Einrichten:**

1. Auslöser anlegen (Verbindung, Ereignis, Einstellungen); die Karte zeigt
   „Shopware-App einrichten“.
2. Adresse von novooa **aus Sicht von Shopware** eintragen (beide in Docker:
   Containername, z. B. `http://novooa:8090`; `localhost` wäre Shopware
   selbst). `manifest.xml` erscheint zum Kopieren.
3. In Shopware `custom/apps/<AppName>/manifest.xml` anlegen und
   `bin/console app:install --activate <AppName>` ausführen.
4. Die Integration der Verbindung braucht Leserechte auf die Entität des
   Ereignisses (der Dialog nennt sie).

Die App heißt `NovooaAusloeser<Kürzel>`, hat genau einen Webhook und kein
Geheimnis außer dem **Token in der Adresse**; das Manifest ist jederzeit neu
abrufbar. Im Lauf liest der Baustein
[„Shopware-Ereignis lesen“](./shopware-ereignis-lesen.md) den Datensatz.

## Siehe auch

- [Verhalten der Shopware-Auslöser](./shopware-ausloeser-verhalten.md)
- [Ereignisquellen-Registry](./ereignisquellen-registry.md)
- [Webhooks](../index/webhooks.md)
