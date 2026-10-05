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

### Bestellung lesen (`getOrder`)

Eingaben: Bestellnummer **oder** Bestell-ID (32 Zeichen; sie hat Vorrang). Eine unbekannte Bestellung ist ein **Fehler**;
wer verzweigen will, nutzt „Bestellungen suchen“ mit Bestellnummer und `found`.

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{bestellung}}` | `json` | die Bestellung im Modell oben |
| `.orderNumber`, `.status`, `.paymentStatus`, `.deliveryStatus`, `.customerEmail` | `string` | die wichtigsten Felder direkt |
| `.total` | `number` | Gesamtbetrag (brutto) |

### Bestellstatus ändern (`changeOrderStatus`)

Eingaben: Bestellung (Nummer oder ID), **Statuswechsel** und „Mail an den Kunden senden“ (Vorgabe **aus**; Shopware
verschickt sonst die Mail der Vorlage).

| Bereich | Wechsel |
| --- | --- |
| Bestellung | In Bearbeitung setzen (`process`), Abschließen (`complete`), Stornieren (`cancel`), Wieder öffnen (`reopen`) |
| Zahlung (jüngste) | Als bezahlt markieren (`paid`), Teilweise bezahlt, Erstatten, Teilweise erstatten, Abbrechen, Wieder öffnen, Erinnern, Als fehlgeschlagen markieren, Autorisieren, Rückbuchung |
| Lieferung (erste) | Als versandt markieren (`ship`), Teilweise versandt, Retoure, Abbrechen, Wieder öffnen |

Aufruf: `POST /api/_action/{order|order_transaction|order_delivery}/{id}/state/{wechsel}` mit `{"sendMail": …}`; danach
liest die Aktion die Bestellung neu. Ist der Wechsel im aktuellen Status nicht erlaubt (400), nennt die Meldung den
aktuellen Status und die **möglichen Wechsel** (`GET /api/_action/state-machine/<entität>/<id>/state`).

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{statuswechsel}}` | `json` | die Bestellung nach dem Wechsel |
| `.previousStatus`, `.newStatus` | `string` | technischer Status des betroffenen Bereichs davor und danach |
| `.changed` | `boolean` | ob sich der Status geändert hat |

**Achtung:** Statuswechsel sind in Shopware nicht ohne Weiteres umkehrbar (z. B. Stornierung) und lösen je nach Shop
Mails und Lagerbuchungen aus.

### Produkte suchen (`searchProducts`)

Eingaben: Name enthält, Artikelnummer, Aktiv (beliebig/ja/nein), Bestand ab/bis (jeweils leer = offen), Reihenfolge
(Name, neueste, geringster Bestand zuerst), Höchstanzahl (1–500, Vorgabe 50). Ausgaben wie „Bestellungen suchen“
(`{{produkte}}`, `.count`, `.total`, `.found`).

**Produktmodell:**

```json
{
  "id": "…", "productNumber": "SW1000", "name": "T-Shirt", "active": true,
  "stock": 12, "availableStock": 10, "price": {"gross": 119, "net": 100},
  "ean": "…", "manufacturer": "Muster GmbH", "parentId": "", "raw": {"…": "…"}
}
```

`price` ist der erste Preis (Standardwährung) und `null`, wenn eine Variante den Preis erbt. `name` kommt aus der
übersetzten Fassung. Gesucht werden Hauptprodukte **und** Varianten.

### Produkt ändern (`updateProduct`)

Eingaben: Produkt (Artikelnummer oder ID), Neuer Bestand, Neuer Preis (brutto), Aktiv (nicht ändern/aktiv/inaktiv).
Geändert wird **nur, was eingetragen ist**; mindestens ein Wert ist Pflicht. Der Preis steht als Zahl (Komma oder Punkt)
und wird mit `linked: true` gesetzt; den **Nettopreis berechnet die Aktion** aus dem Steuersatz des Produkts (bei
Varianten ohne eigenen Satz aus dem Hauptprodukt; ist er nicht bestimmbar, wird nichts geändert). Preise anderer
Währungen bleiben erhalten; hat das Produkt noch keinen Preis, gilt die Standardwährung des Shops.

Ausgaben: `{{produkt}}` (Produkt nach der Änderung, neu gelesen) und `.changed` (`boolean`: Bestand, Aktiv oder
Bruttopreis haben sich tatsächlich geändert).

### Kunden suchen (`searchCustomers`)

Eingaben: E-Mail enthält, Name enthält (Vorname, Nachname **oder** Firma), Kundennummer, Aktiv, Reihenfolge (neueste,
Nachname A–Z), Höchstanzahl. Ausgaben `{{kunden}}`, `.count`, `.total`, `.found`.

**Kundenmodell:**

```json
{
  "id": "…", "customerNumber": "K1", "email": "…", "firstName": "…", "lastName": "…", "company": "",
  "active": true, "guest": false, "group": "Standard-Kundengruppe", "createdAt": "…",
  "billingAddress": {"street": "…", "zip": "…", "city": "…", "country": "…"}, "raw": {"…": "…"}
}
```

### Shopware-Abfrage (`query`, Experte)

Fragt **lesend** eine beliebige Entität ab (`POST /api/search/<entität>`). Eingaben: Entität (z. B. `order`, `product`,
`customer`, `tax`), **Kriterien als JSON** (Shopware-Suchkriterien: `filter`, `sort`, `associations`, `includes`, …;
Templates erlaubt), Seite und Höchstanzahl. `limit`, `page` und `total-count-mode` gehören **nicht** in die Kriterien.
Ausgaben: `{{abfrage}}` (die rohen Datensätze), `.count`, `.total`, `.found`. Für Schreibzugriffe gibt es die eigenen
Aktionen oder die [HTTP-Anfrage](./verbindungen.md).

### Shopware-Ereignis lesen (`readEvent`)

Der Gegenpart zu den Auslösern (nächster Abschnitt): gibt Datensatz und Art des Ereignisses aus, das den Lauf gestartet
hat. Braucht **keine Verbindung** und funktioniert nur in Aufgaben mit einem Shopware-Auslöser (sonst Fehlermeldung).
Ausgaben: `{{ereignis}}` (der Datensatz im einfachen Modell: Bestellung, Kunde, Produkt oder Newsletter-Anmeldung, je
nach Auslöser), `.event` (`orderPlaced`, `orderStatus`, `customerRegistered`, `stockLow`, `newsletterSubscribed`), `.id`,
`.receivedAt`. Felder des Datensatzes: `{{ereignis.orderNumber}}`, `{{ereignis.email}}` usw. (Modelle wie bei den Aktionen).

## Auslöser (App-Webhooks)

Quelle **„Shopware-Ereignis“** unter Zeitplan → Auslöser → Ereignis. Shopware meldet das Ereignis über eine **kleine
Shopware-App**, die novooa je Auslöser als `manifest.xml` erzeugt; novooa lädt den Datensatz über die gewählte Verbindung
nach und startet die Aufgabe mit dem Datensatz im einfachen Modell. Technisch ist es der [Webhook-Empfänger](./webhooks.md)
mit einem Interpreter für diese Quelle.

| Ereignis                  | Shopware-Ereignis                                | Einstellungen                                          |
| ------------------------- | ------------------------------------------------ | ------------------------------------------------------ |
| **Neue Bestellung**       | `checkout.order.placed`                          | –                                                      |
| **Bestellstatus erreicht**| `state_enter.<order\|order_transaction\|order_delivery>.state.<status>` | Bereich (Bestellung, Zahlung, Lieferung), Zielstatus |
| **Neuer Kunde**           | `checkout.customer.register`                     | –                                                      |
| **Bestand unterschritten**| `product.written`                                | Bestand höchstens N                                    |
| **Newsletter-Anmeldung**  | `newsletter.confirmed` oder `newsletter.register`| Erst nach Bestätigung (Standard an)                    |

**Einrichten:**

1. Auslöser anlegen (Verbindung wählen, Ereignis, Einstellungen). Die Karte des Auslösers zeigt „Shopware-App einrichten“.
2. Im Dialog die Adresse von novooa **aus Sicht von Shopware** eintragen (laufen beide in Docker: der Containername, z. B.
   `http://novooa:8090`; `localhost` meint im Shopware-Container Shopware selbst). `manifest.xml` erscheint zum Kopieren.
3. In der Shopware-Installation `custom/apps/<AppName>/manifest.xml` anlegen und `bin/console app:install --activate
   <AppName>` ausführen (der Dialog nennt Name und Befehl).
4. Die Integration der Verbindung braucht Leserechte auf die Entität des Ereignisses (der Dialog nennt sie), weil novooa die
   Daten darüber nachlädt.

Die App ist je Auslöser eigen (Name `NovooaAusloeser<Kürzel>`), enthält genau einen Webhook und keine Geheimnisse außer dem
**Token in der Adresse** (derselbe wie bei jedem Webhook-Auslöser). Das Manifest lässt sich jederzeit neu anzeigen.

**Verhalten:**
- Aufrufe, deren Ereignisname nicht zum Auslöser passt, starten nichts (Antwort 202).
- **Bestand unterschritten** wird bei jeder Änderung des Bestands gemeldet, solange er an oder unter der Grenze liegt (nicht
  nur beim Überschreiten; Shopware nennt den vorherigen Bestand nicht). Änderungen ohne das Feld `stock`, Löschungen und
  Nicht-Produkte werden übersprungen; je Aufruf werden höchstens 50 Produkte nachgeladen.
- Ein Aufruf startet höchstens 10 Läufe. Schlägt das Nachladen fehl (Shop nicht erreichbar, Recht fehlt), antwortet novooa
  mit einem Fehler, damit Shopware es erneut versucht.
- Es gilt die Begrenzung der Webhooks (je Auslöser im Schnitt 5 Aufrufe pro Sekunde).

**Nicht geprüft** (aus der Shopware-Dokumentation übernommen, nicht gegen einen Shop): ob eine App **ohne `<setup>`** ihre
Webhooks sendet, `manifest-2.0.xsd` in 6.6, die Form der Nutzlast (der Code liest tolerant und braucht je Ereignis nur die
Kennung: `order.id`, `orderTransaction.orderId`, `customer.id`, `newsletterRecipient.id`, bei `product.written` die Einträge
mit `primaryKey` und `updatedFields`) sowie `newsletter.confirmed` bei abgeschaltetem Double-Opt-in. Die Aufrufe sind **nicht
signiert** (Schutz ist das Token in der Adresse); eine Signaturprüfung mit App-Geheimnis folgt, wenn sie am echten Shop
geprüft ist. Schlägt etwas fehl, hilft das Protokoll der Webhooks in Shopware (Einstellungen → System → Webhooks) und
`bin/console messenger:consume` (Zustellung läuft über die Warteschlange).

## Fehler

Shopware-Fehler erscheinen als verständliche Meldung am Baustein: abgelehnte Anmeldung (401), fehlende Berechtigung der
Integration mit dem Namen des Rechts (403), unbekannte Adresse (404), Begrenzung (429), Fehler des Shops (5xx). Eingaben
werden geprüft, bevor etwas gesendet wird (unbekannter Status, ungültiges Datum, Limit außerhalb 1–500).

## Nicht umgesetzt

Signierte App-Aufrufe (App-Geheimnis), Auslöser per Abfrage im Takt (ohne App und öffentliche Adresse), Dokumente (Rechnung, Lieferschein; braucht Binärantworten im HTTP-Client), Sprachwahl,
Anlegen von Datensätzen, Schreibzugriffe über die Experten-Abfrage. Der KI-Agent kennt die Bausteine nicht.
