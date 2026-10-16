# Shopware-Bestellmodell

> Bestellungen erscheinen in einem einfachen, stabilen Modell; das Originalobjekt steht unter `raw`.

Gehört zu: [Integrationen](../index/integrationen.md)

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

- Zahlungs- und Lieferstatus stammen von der **jüngsten Zahlung** bzw. der
  **ersten Lieferung**.
- Bezeichnungen (`…Label`, Methoden, Länder) in der Sprache des Shops.
- Fehlende Teile bleiben leer (`""`, `0`, `null` für Adressen).

## Siehe auch

- [Shopware: Bestellungen suchen und lesen](./shopware-bestellungen.md)
- [Shopware: Bestellstatus ändern](./shopware-bestellstatus-aendern.md)
