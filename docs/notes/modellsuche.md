# Modellsuche

> `SearchModelCatalog` sucht nach Aufgabe, Sprachen und Begriffen; im Aufgabenstudio filtern Chips nach Aufgabe und Sprache.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

## Use Case

- `ModelSearchCriteria`: Aufgabe, Sprachen, Suchbegriffe, Limit ≤ 20.
- Ohne Team nur globaler Katalog (`SystemModelCatalog.listSystemEntries`),
  sonst System- und Teammodelle.
- Sprachunabhängige Modelle passen zu jeder Sprache.
- Sortierung nach Zahl passender Begriffe in ID, Titel, Beschreibung,
  Aufgabe, Tags und Übersetzungen; ein Begriff trifft auch Bezeichnungen und
  Synonyme der Tags samt Obertags ([Tag-Vokabular](./modell-tag-vokabular.md)).
- Die Treffer des Tools nennen die Themen auf Deutsch (`themen`).
- Nutzer: das Tool `sucheModelle` des
  [KI-Agenten](./multiagenten-aufgabenstudio.md).

## Suchdialog im Aufgabenstudio

- Chips für Aufgabe und Thema (je Einfachauswahl) und Sprache
  (Mehrfachauswahl), nur mit Treffern und deren Anzahl. Themen sind die
  Obertags; ein Untertag zählt zu seinem Obertag, unbekannte Freitext-Tags
  älterer Einträge zählen nicht.
- Treffer in mehreren Bereichen und mehr als sechs Aufgaben-Chips → erst eine
  Bereichsebene, danach nur dessen Aufgaben.
- Bausteine mit fester Aufgabe („Text vorlesen“, „Audio transkribieren“)
  blenden die Aufgaben-Chips aus.
- Die Textsuche findet auch die deutschen Bezeichnungen von Aufgabe und
  Sprache sowie Tag-Bezeichnungen und Synonyme aller Sprachen.
- Eigene Modelle erscheinen ebenfalls.

## Siehe auch

- [Modellaufgaben, Sprachen und Tags](./modellaufgaben-und-sprachen.md)
- [Persistenz des Modellkatalogs](./modellkatalog-persistenz.md)
