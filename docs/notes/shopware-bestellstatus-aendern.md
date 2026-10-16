# Shopware: Bestellstatus ändern

> `changeOrderStatus` führt einen Statuswechsel für Bestellung, jüngste Zahlung oder erste Lieferung aus; Wechsel sind in Shopware oft nicht umkehrbar.

Gehört zu: [Integrationen](../index/integrationen.md)

Eingaben: Bestellung (Nummer oder ID), **Statuswechsel**, „Mail an den Kunden
senden“ (Vorgabe **aus**; sonst verschickt Shopware die Mail der Vorlage).

| Bereich | Wechsel |
| --- | --- |
| Bestellung | In Bearbeitung setzen (`process`), Abschließen (`complete`), Stornieren (`cancel`), Wieder öffnen (`reopen`) |
| Zahlung (jüngste) | Als bezahlt markieren (`paid`), Teilweise bezahlt, Erstatten, Teilweise erstatten, Abbrechen, Wieder öffnen, Erinnern, Als fehlgeschlagen markieren, Autorisieren, Rückbuchung |
| Lieferung (erste) | Als versandt markieren (`ship`), Teilweise versandt, Retoure, Abbrechen, Wieder öffnen |

- Aufruf: `POST /api/_action/{order|order_transaction|order_delivery}/{id}/state/{wechsel}`
  mit `{"sendMail": …}`, danach wird die Bestellung neu gelesen.
- Unerlaubter Wechsel (400): Die Meldung nennt aktuellen Status und mögliche
  Wechsel (`GET /api/_action/state-machine/<entität>/<id>/state`).

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{statuswechsel}}` | `json` | Bestellung nach dem Wechsel |
| `previousStatus`, `newStatus` | `string` | technischer Status davor und danach |
| `changed` | `boolean` | ob sich der Status geändert hat |

**Achtung:** Wechsel wie Stornierung lösen je nach Shop Mails und
Lagerbuchungen aus.

## Siehe auch

- [Shopware-Bestellmodell](./shopware-bestellmodell.md)
- [Shopware-Auslöser](./shopware-ausloeser.md) — „Bestellstatus erreicht“
