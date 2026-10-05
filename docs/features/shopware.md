# Feature: Shopware

Verwandt: [`integrationen.md`](./integrationen.md) · [`verbindungen.md`](./verbindungen.md) ·
[`aufgabe.md`](./aufgabe.md) · [`../node-executor-outputs.md`](../node-executor-outputs.md)

## Zweck

Das Shopware-Plugin bindet einen Shopware-6-Shop (Zielversion **6.6**) über dessen Admin-API an. Jede Aktion ist für
Nutzer:innen ein eigener Baustein mit eigenem Formular und eigenen Ausgaben; sie liefern ein einfaches, stabiles
Modell statt der rohen Shopware-Objekte.

**Verfügbarkeit:** Standalone (braucht [Verbindungen](./verbindungen.md)). Die Palette zeigt die Gruppe „Shopware“ nur dort.

> **Nicht gegen einen echten Shop geprüft.** Die API-Formen stammen aus der Dokumentation und Erfahrung mit Shopware 6.x;
> die Entwicklungsumgebung hatte keinen Shop. Getestet wird gegen einen Fake. Vor dem ersten Einsatz die
> OpenAPI-Spezifikation des Shops (`/api/_info/openapi3.json`) mit den Annahmen abgleichen.

## Einrichten

1. In Shopware unter *Einstellungen → System → Integrationen* eine Integration anlegen und ihr die Rechte geben, die die
   genutzten Aktionen brauchen (für „Bestellungen suchen“ mindestens lesen für Bestellung und die zugehörigen
   Entitäten). Zugriffsschlüssel-ID und Geheimen Zugriffsschlüssel notieren.
2. In novooa unter *Einstellungen → Verbindungen* eine Verbindung mit der **Vorlage „Shopware“** anlegen: Basis-URL ist
   die Shop-Adresse (ohne `/api`), die Token-URL leitet die Vorlage ab. Die Token-Anfrage geht als JSON.
3. Im Aufgabenstudio den Baustein aus der Gruppe „Shopware“ wählen und die Verbindung eintragen.

## Aufbau

- **Backend:** `functions/src/features/integrations/shopware/`. Ein Executor für das Primitive `shopware`
  (`config: {action, connectionId, params}`); jede Aktion liegt in `actions/` und meldet sich in `shopware-plugin.ts` an.
  `ShopwareClient` sendet über die Verbindung (`POST /api/search/<entity>` mit Kriterien, Seiten bis 500, Fehlerabbildung
  auf deutsche Meldungen).
- **Client:** `lib/features/integrations/shopware/`. `ShopwareActions` beschreibt die Felder und Ausgaben jeder Aktion;
  ein gemeinsames Formular (`ShopwareActionWidget`) rendert sie. `registerShopwarePlugin` meldet je Aktion ein
  `PluginNodeModule` an (`typeId` `shopware.<aktion>`, gemeinsames Primitive `shopware`).
- Eine neue Aktion: eine Datei im Backend (`actions/`) und ein Eintrag in `ShopwareActions` im Client. Die Auswahllisten
  (Status) stehen in beiden und müssen übereinstimmen.

## Aktionen

### Bestellungen suchen (`searchOrders`)

| Eingabe | Bedeutung |
| --- | --- |
| Bestellt ab / bis | Datum oder Zeitpunkt (ISO 8601), Templates erlaubt; leer = keine Grenze. Reine Datumsangaben gelten ab 00:00 UTC |
| Bestellstatus | Offen, In Bearbeitung, Abgeschlossen, Storniert |
| Zahlungsstatus | Offen, Bezahlt, Teilweise bezahlt, Erstattet, … (jede Zahlung der Bestellung zählt) |
| Lieferstatus | Offen, Versandt, Teilweise versandt, Retourniert, … |
| E-Mail des Kunden, Bestellnummer | genau |
| Reihenfolge | neueste oder älteste zuerst |
| Höchstanzahl | 1 bis 500, Vorgabe 50 |

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{bestellungen}}` | `json` | Liste von Bestellungen im Modell unten |
| `{{bestellungen.count}}` | `number` | Anzahl der gelieferten Bestellungen |
| `{{bestellungen.total}}` | `number` | Anzahl aller passenden Bestellungen in Shopware |
| `{{bestellungen.found}}` | `boolean` | mindestens eine Bestellung |

Die Liste lässt sich mit „Für jedes Element“ durchlaufen. **Bestellmodell:**

```json
{
  "id": "…", "orderNumber": "10001", "createdAt": "2026-10-05T08:30:12.123+00:00",
  "status": "open", "statusLabel": "Offen",
  "paymentStatus": "paid", "paymentStatusLabel": "Bezahlt",
  "deliveryStatus": "shipped", "deliveryStatusLabel": "Versandt",
  "currency": "EUR", "total": 119, "netTotal": 100,
  "customer": {"id": "…", "number": "K1", "email": "…", "firstName": "…", "lastName": "…", "company": ""},
  "billingAddress": {"firstName": "…", "lastName": "…", "company": "", "street": "…", "zip": "…", "city": "…", "country": "…"},
  "shippingAddress": {"…": "wie billingAddress"},
  "shippingMethod": "Standard", "paymentMethod": "Rechnung", "customerComment": "",
  "lineItems": [{"id": "…", "label": "T-Shirt", "productNumber": "SW1000", "quantity": 2, "unitPrice": 50, "total": 100, "type": "product"}],
  "raw": {"…": "das Objekt, wie Shopware es geliefert hat"}
}
```

Zahlungs- und Lieferstatus stammen von der **jüngsten Zahlung** bzw. der **ersten Lieferung**; die Bezeichnungen
(`…Label`, Methoden, Länder) stehen in der Sprache des Shops. Fehlt ein Teil, bleibt das Feld leer (`""`, `0`, `null`
für Adressen). Der Filter auf Zahlungs- oder Lieferstatus trifft eine Bestellung, sobald **irgendeine** Zahlung bzw.
Lieferung den Status hat, `paymentStatus` zeigt dagegen nur die jüngste.

## Fehler

Shopware-Fehler erscheinen als verständliche Meldung am Baustein: abgelehnte Anmeldung (401), fehlende Berechtigung der
Integration mit dem Namen des Rechts (403), unbekannte Adresse (404), Begrenzung (429), Fehler des Shops (5xx). Eingaben
werden geprüft, bevor etwas gesendet wird (unbekannter Status, ungültiges Datum, Limit außerhalb 1–500).

## Nicht umgesetzt

Weitere Aktionen (Bestellung lesen, Bestellstatus ändern, Produkte suchen/ändern, Kunden suchen, Experten-Abfrage), der
Auslöser „Neue Bestellung“, Dokumente (Rechnung, Lieferschein; braucht Binärantworten im HTTP-Client), Sprachwahl,
Anlegen von Datensätzen. Der KI-Agent kennt die Bausteine nicht.
