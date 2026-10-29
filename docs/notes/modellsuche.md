# Modellsuche

> `SearchModelCatalog` sucht nach Aufgabe, Sprachen und Begriffen; im Aufgabenstudio filtert eine Filterspalte nach Bereich, Aufgabe, Thema und Sprache.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

## Use Case

- `ModelSearchCriteria`: Aufgabe, Sprachen, Suchbegriffe, Limit ≤ 20.
- Ohne Team nur globaler Katalog (`SystemModelCatalog.listSystemEntries`),
  sonst System- und Teammodelle.
- Sprachunabhängige Modelle passen zu jeder Sprache.
- Sortierung nach Zahl passender Begriffe in ID, Titel, Beschreibung,
  Aufgabe, Tags und Übersetzungen; ein Begriff trifft auch Bezeichnungen und
  Synonyme der Tags samt Obertags ([Tag-Vokabular](./modell-tag-vokabular.md)).
- Die Treffer des Tools nennen die Themen auf Deutsch (`topics`).
- Nutzer: das Tool `searchModels` des
  [KI-Agenten](./multiagenten-aufgabenstudio.md).

## Suchdialog im Aufgabenstudio

- Adaptives Sheet wie die übrigen Auswahl-Sheets
  (`showAdaptiveSheet`): am Desktop ein Fenster-Sheet (880 breit, damit
  Filter und Treffer nebeneinander passen), sonst ein Bottom Sheet.
- **Layout nach verfügbarer Breite** (ab 640): links eine Filterspalte,
  rechts Suche und Treffer. Schmaler öffnet ein Knopf „Filter“ (mit Zahl der
  aktiven Filter) die Gruppen als eigene Seite im Sheet; „Treffer anzeigen
  (n)“ führt zurück.
- Gruppen Bereich, Aufgabe und Thema (je Einfachauswahl) und Sprache
  (Mehrfachauswahl), Optionen nach Trefferzahl absteigend, jede mit ihrer
  Anzahl unter den übrigen Filtern. Eine Gruppe erscheint nur mit mehr als
  einer Option oder einer Auswahl.
- Längere Gruppen zeigen die ersten fünf Optionen und klappen über „Alle
  anzeigen (n)“ auf; gewählte Optionen bleiben immer sichtbar.
- Aktive Filter stehen als entfernbare Chips über den Treffern, dazu „Filter
  zurücksetzen“.
- Themen sind die Obertags; ein Untertag zählt zu seinem Obertag, unbekannte
  Freitext-Tags älterer Einträge zählen nicht.
- Treffer in mehreren Bereichen und mehr als sechs Aufgaben → zusätzlich die
  Gruppe Bereich; ein Bereich grenzt die Aufgaben ein.
- Bausteine mit fester Aufgabe („Text vorlesen“, „Audio transkribieren“)
  blenden Bereich und Aufgabe aus.
- Die Textsuche findet auch die deutschen Bezeichnungen von Aufgabe und
  Sprache sowie Tag-Bezeichnungen und Synonyme aller Sprachen.
- Eigene Modelle erscheinen ebenfalls.

## Siehe auch

- [Modellaufgaben, Sprachen und Tags](./modellaufgaben-und-sprachen.md)
- [Persistenz des Modellkatalogs](./modellkatalog-persistenz.md)
