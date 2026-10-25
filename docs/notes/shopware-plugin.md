# Shopware-Plugin

> Das Shopware-Plugin bindet einen Shopware-6-Shop (Ziel 6.6) über die Admin-API an; jede Aktion ist ein eigener Baustein mit einfachem, stabilem Ausgabemodell.

Gehört zu: [Integrationen](../index/integrationen.md)

> **Nicht gegen einen echten Shop geprüft.** API-Formen stammen aus Doku und
> Erfahrung; getestet wird gegen einen Fake. Vor dem ersten Einsatz die
> OpenAPI-Spezifikation des Shops (`/api/_info/openapi3.json`) abgleichen.

- **Palette:** Gruppe „Shopware“, Icon `Icons.storefront_outlined`; die
  Aktionen brauchen eine [Verbindung](./verbindung.md).
- **Backend** (`functions/src/features/integrations/shopware/`): ein Executor
  für das Primitive `shopware` (`config: {action, connectionId, params}`); jede
  Aktion liegt in `actions/` und meldet sich in `shopware-plugin.ts` an.
  `ShopwareClient` sendet über die Verbindung (`POST /api/search/<entity>`,
  Seiten bis 500, Fehler als deutsche Meldungen).
- **Client** (`lib/features/integrations/shopware/`): `ShopwareActions`
  beschreibt Felder und Ausgaben je Aktion; `ShopwareActionWidget` rendert das
  Formular; `registerShopwarePlugin` meldet je Aktion ein `PluginNodeModule`
  (`typeId` `shopware.<aktion>`, gemeinsames Primitive `shopware`).
- **Neue Aktion:** eine Datei in `actions/` und ein Eintrag in
  `ShopwareActions`. Auswahllisten (Status) stehen in beiden und müssen
  übereinstimmen.
- Der KI-Agent kennt die Bausteine nicht.

## Siehe auch

- [Shopware einrichten](./shopware-einrichten.md)
- [Shopware-Fehler und Grenzen](./shopware-fehler-und-grenzen.md)
- [Integrations-Plugins](./integrations-plugins.md)
