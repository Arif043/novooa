# Shopware: Bestellungen suchen und lesen

> „Bestellungen suchen“ liefert eine filterbare Liste samt Anzahl und Treffer-Flag; „Bestellung lesen“ holt genau eine Bestellung und scheitert, wenn es sie nicht gibt.

Gehört zu: [Integrationen](../index/integrationen.md)

## Bestellungen suchen (`searchOrders`)

| Eingabe | Bedeutung |
| --- | --- |
| Bestellt ab / bis | Datum oder Zeitpunkt (ISO 8601), Templates erlaubt; leer = offen. Reine Daten ab 00:00 UTC |
| Bestellstatus | Offen, In Bearbeitung, Abgeschlossen, Storniert |
| Zahlungsstatus | Offen, Bezahlt, Teilweise bezahlt, Erstattet, … |
| Lieferstatus | Offen, Versandt, Teilweise versandt, Retourniert, … |
| E-Mail des Kunden, Bestellnummer | genau |
| Reihenfolge | neueste oder älteste zuerst |
| Höchstanzahl | 1 bis 500, Vorgabe 50 |

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{bestellungen}}` | `json` | Liste im [Bestellmodell](./shopware-bestellmodell.md) |
| `{{Anzahl}}` (`count`) | `number` | gelieferte Bestellungen |
| `{{Gesamt}}` (`total`) | `number` | alle passenden in Shopware |
| `{{Gefunden}}` (`found`) | `boolean` | mindestens eine |

Der Filter auf Zahlungs- oder Lieferstatus trifft, sobald **irgendeine**
Zahlung bzw. Lieferung den Status hat; `paymentStatus` zeigt nur die jüngste.
Die Liste lässt sich mit „Für jedes Element“ durchlaufen.

## Bestellung lesen (`getOrder`)

Eingabe: Bestellnummer **oder** Bestell-ID (32 Zeichen, hat Vorrang). Eine
unbekannte Bestellung ist ein **Fehler**; zum Verzweigen „Bestellungen
suchen“ mit Bestellnummer und `found` nutzen.

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{bestellung}}` | `json` | die Bestellung |
| `orderNumber`, `status`, `paymentStatus`, `deliveryStatus`, `customerEmail` | `string` | wichtigste Felder |
| `total` | `number` | Gesamtbetrag (brutto) |

## Siehe auch

- [Shopware: Bestellstatus ändern](./shopware-bestellstatus-aendern.md)
- [Baustein „Für jedes Element“](./foreach-baustein.md)
