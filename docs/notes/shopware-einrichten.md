# Shopware einrichten

> Plugin einschalten, in Shopware eine Integration anlegen, in novooa eine Verbindung mit der Vorlage „Shopware“, dann die Bausteine nutzen.

Gehört zu: [Integrationen](../index/integrationen.md)

1. novooa: *Einstellungen → Plugins* — „Shopware“ einschalten (nur Admins;
   [Plugins aktivieren](./plugin-aktivierung.md)).
2. Shopware: *Einstellungen → System → Integrationen* — Integration mit den
   nötigen Rechten anlegen (für „Bestellungen suchen“ mindestens Lesen für
   Bestellung und zugehörige Entitäten). Zugriffsschlüssel-ID und geheimen
   Zugriffsschlüssel notieren.
3. novooa: *Einstellungen → Verbindungen* — Verbindung mit **Vorlage
   „Shopware“**. Basis-URL ist die Shop-Adresse ohne `/api`; die Token-URL
   leitet die Vorlage ab; die Token-Anfrage geht als JSON.
4. Aufgabenstudio: Baustein aus der Gruppe „Shopware“ wählen und die
   Verbindung eintragen.

Auslöser brauchen zusätzlich eine kleine Shopware-App, siehe
[Shopware-Auslöser](./shopware-ausloeser.md).

## Siehe auch

- [Shopware-Plugin](./shopware-plugin.md)
- [Verbindungen](../index/verbindungen.md)
