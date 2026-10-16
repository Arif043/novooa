# „Datei schreiben“: Ziel und Dialog

> „Datei schreiben“ ist ein Persistenz-Output: Er legt eine neue Datei in einem wählbaren Ordner an oder schreibt eine neue Version einer bestehenden Datei.

Gehört zu: [Dateien](../index/dateien.md)

- Ziel: `folderId` in der Node-Config (ohne Angabe: oberste Ebene) oder eine
  bestehende Datei, die in ihrem Ordner bleibt.
- Gibt es auf der obersten Ebene schon eine Datei gleichen Namens, entsteht
  keine zweite, sondern eine neue Version unter deren `fileId`.
- Ein Bild-Prompt-Output als Base64-Data-URL wird dekodiert und binär
  gespeichert; MIME-Type und Endung kommen aus der Data-URL und ersetzen eine
  konfigurierte Text-Endung.
- Den Content-Type bestimmt der Executor (`text/plain`, bei Bildern und
  Tabellen aus dem Quellwert).

**Dialog im Aufgabenstudio** (kein technisches Datei-ID-Feld):

- bestehende Datei wählen, filterbar per Chips nach Kategorie (Text, Bilder,
  Video, Audio, PDF, Tabellen; nur Kategorien mit Dateien), oder
- „Neu“: Dateiname und Zielordner; „Neuer Ordner“ legt im gewählten Ordner an.

## Siehe auch

- [Datei-Bausteine](./datei-bausteine.md) — Outputs
- [Datei-Ereignisse lösen Aufgaben aus](./datei-ereignisse-dispatch.md)
