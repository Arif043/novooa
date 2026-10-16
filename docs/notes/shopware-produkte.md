# Shopware: Produkte suchen und ändern

> „Produkte suchen“ findet Haupt- und Variantenprodukte; „Produkt ändern“ setzt nur eingetragene Werte und berechnet den Nettopreis selbst.

Gehört zu: [Integrationen](../index/integrationen.md)

## Produkte suchen (`searchProducts`)

Eingaben: Name enthält, Artikelnummer, Aktiv (beliebig/ja/nein), Bestand
ab/bis (leer = offen), Reihenfolge (Name, neueste, geringster Bestand zuerst),
Höchstanzahl (1–500, Vorgabe 50). Ausgaben `{{produkte}}`, `count`, `total`,
`found`.

```json
{
  "id": "…", "productNumber": "SW1000", "name": "T-Shirt", "active": true,
  "stock": 12, "availableStock": 10, "price": {"gross": 119, "net": 100},
  "ean": "…", "manufacturer": "Muster GmbH", "parentId": "", "raw": {"…": "…"}
}
```

`price` ist der erste Preis (Standardwährung), `null`, wenn eine Variante den
Preis erbt; `name` aus der übersetzten Fassung.

## Produkt ändern (`updateProduct`)

Eingaben: Produkt (Artikelnummer oder ID), neuer Bestand, neuer Preis
(brutto), Aktiv (nicht ändern/aktiv/inaktiv). Nur Eingetragenes wird
geändert; mindestens ein Wert ist Pflicht.

- Preis als Zahl (Komma oder Punkt), gesetzt mit `linked: true`. Den
  **Nettopreis berechnet die Aktion** aus dem Steuersatz (bei Varianten ohne
  eigenen Satz aus dem Hauptprodukt; nicht bestimmbar → keine Änderung).
- Preise anderer Währungen bleiben; ohne bisherigen Preis gilt die
  Standardwährung.
- Ausgaben: `{{produkt}}` (neu gelesen), `changed` (Bestand, Aktiv oder
  Bruttopreis haben sich wirklich geändert).

## Siehe auch

- [Shopware-Auslöser](./shopware-ausloeser.md) — „Bestand unterschritten“
- [Shopware: Kunden suchen und Abfrage](./shopware-kunden-und-abfrage.md)
