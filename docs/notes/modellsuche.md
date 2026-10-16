# Modellsuche

> `SearchModelCatalog` sucht nach Aufgabe, Sprachen und Begriffen; im Aufgabenstudio filtern Chips nach Aufgabe und Sprache.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

## Use Case

- `ModelSearchCriteria`: Aufgabe, Sprachen, Suchbegriffe, Limit ≤ 20.
- Ohne Team nur globaler Katalog (`SystemModelCatalog.listSystemEntries`),
  sonst System- und Teammodelle.
- Sprachunabhängige Modelle passen zu jeder Sprache.
- Sortierung nach Zahl passender Begriffe in ID, Titel, Beschreibung,
  Aufgabe, Tags und Übersetzungen.
- Nutzer: das Tool `sucheModelle` des
  [KI-Agenten](../features/ki-agent.md#multiagenten-architektur-aufgabenstudio).

## Suchdialog im Aufgabenstudio

- Chips für Aufgabe (Einfachauswahl) und Sprache (Mehrfachauswahl), nur mit
  Treffern und deren Anzahl.
- Treffer in mehreren Bereichen und mehr als sechs Aufgaben-Chips → erst eine
  Bereichsebene, danach nur dessen Aufgaben.
- Bausteine mit fester Aufgabe („Text vorlesen“, „Audio transkribieren“)
  blenden die Aufgaben-Chips aus.
- Die Textsuche findet auch die deutschen Bezeichnungen von Aufgabe und
  Sprache.
- Eigene Modelle (Standalone) erscheinen ebenfalls.

## Siehe auch

- [Modellaufgaben, Sprachen und Tags](./modellaufgaben-und-sprachen.md)
- [Persistenz des Modellkatalogs](./modellkatalog-persistenz.md)
