# Shopware: Kunden suchen und Abfrage

> „Kunden suchen“ liefert Kunden im einfachen Modell; die Experten-„Abfrage“ liest jede Entität mit eigenen Suchkriterien, aber nur lesend.

Gehört zu: [Integrationen](../index/integrationen.md)

## Kunden suchen (`searchCustomers`)

Eingaben: E-Mail enthält, Name enthält (Vorname, Nachname **oder** Firma),
Kundennummer, Aktiv, Reihenfolge (neueste, Nachname A–Z), Höchstanzahl.
Ausgaben `{{kunden}}`, `count`, `total`, `found`.

```json
{
  "id": "…", "customerNumber": "K1", "email": "…", "firstName": "…", "lastName": "…", "company": "",
  "active": true, "guest": false, "group": "Standard-Kundengruppe", "createdAt": "…",
  "billingAddress": {"street": "…", "zip": "…", "city": "…", "country": "…"}, "raw": {"…": "…"}
}
```

## Shopware-Abfrage (`query`, Experte)

- `POST /api/search/<entität>` für eine beliebige Entität (`order`,
  `product`, `customer`, `tax` …).
- **Kriterien als JSON** (`filter`, `sort`, `associations`, `includes` …;
  Templates erlaubt), dazu Seite und Höchstanzahl. `limit`, `page` und
  `total-count-mode` gehören **nicht** in die Kriterien.
- Ausgaben: `{{abfrage}}` (rohe Datensätze), `count`, `total`, `found`.
- Schreiben geht nur über die eigenen Aktionen oder die
  [HTTP-Anfrage](../features/verbindungen.md).

## Siehe auch

- [Shopware: Produkte suchen und ändern](./shopware-produkte.md)
- [Shopware-Plugin](./shopware-plugin.md)
