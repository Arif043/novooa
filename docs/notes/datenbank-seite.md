# Datenbank-Seite

> Die Seite „Datenbank“ zeigt Sammlungen als Excel-artige Arbeitsblätter: Sammlungen anlegen, umbenennen, leeren und löschen; Datensätze anlegen, bearbeiten, sortieren, auswählen und gemeinsam löschen; Import und Export als CSV oder JSON.

Gehört zu: [Daten](../index/daten.md)

- **Übersicht:** alle Sammlungen als Blatt mit Anzahl; „Sammlung anlegen“
  oben rechts, je Zeile ein Menü (⋯) mit Umbenennen, Leeren, Löschen. Ohne
  Sammlungen ein leerer Zustand mit „Sammlung anlegen“. Sammlungen entstehen
  weiterhin auch automatisch, wenn ein Arbeitsplan hineinschreibt.
- **Blatt einer Sammlung:** Zurück, Name, „Datensatz anlegen“ und ein Menü
  (⋯) mit Importieren, Exportieren als CSV/JSON, Umbenennen, Leeren, Löschen —
  seltene Aktionen bewusst im Menü (Hick's Law).
- Darstellung: Spaltenbuchstaben, Zeilennummern, Zellraster, feste
  Kopfzeile, horizontaler Bildlauf; Sammlungsreiter wechseln das Blatt.
  Zeilen öffnen den Editor — keine direkte Zellbearbeitung. Zeilen werden beim
  Scrollen bedarfsgerecht aufgebaut.
- **Sortieren:** Klick auf einen Spaltenkopf sortiert aufsteigend, erneut
  absteigend, ein drittes Mal wieder nach Änderungszeit; ein Pfeil zeigt die
  Richtung. Die Runtime sortiert, damit Export und Ansicht dieselbe Ordnung
  haben. Felder mit Leer- oder Sonderzeichen im Namen sind nicht sortierbar.
- **Auswahl:** Checkbox-Spalte, Kopf-Checkbox für alle sichtbaren. Bei
  Auswahl ersetzt „n ausgewählt · Löschen · Auswahl aufheben“ den Hinweis über
  dem Blatt. Such-, Filter- und Sammlungswechsel heben die Auswahl auf;
  gelöschte Datensätze verlassen sie beim Neuladen.
- **Rückfragen:** Leeren und Löschen nennen Name und Anzahl; Umbenennen warnt,
  dass Bausteine mit dem alten Namen beim nächsten Lauf eine neue Sammlung
  anlegen. Ein belegter Name wird gemeldet.
- Suche über alle skalaren Feldwerte; strukturierte Filter (Feld, Vergleich,
  Wert) gehen an die Runtime. Die Ansicht zeigt höchstens 500 Datensätze.
- Die technische Datensatz-ID erscheint nicht in der Oberfläche.
- Editor: Werte werden als Zahl oder Boolean erkannt, sonst Text;
  verschachtelte Werte als gültiges JSON bearbeitbar.
- Filter, Editor und Werkzeugleiste brechen bei schmalen Fenstern oder großer
  Schrift um; bei wenig Höhe scrollt die Arbeitsfläche (Mindesthöhe wächst mit
  der Schriftgröße).
- Aufbau: `DatabaseCubit` (Laden, Suche, Filter, Sortierung, Auswahl,
  einzelne Datensätze), `DatabaseActionsCubit` (Sammlungen, Mehrfachlöschen,
  Export) und `DatabaseImportCubit` (Datei → Vorschau → übernehmen).
  Rückmeldungen als Snackbar, Texte über `LocaleKeys` (`ui.db_*`).
- Stil „Luminous Precision“.

## Siehe auch

- [Import und Export von Datensammlungen](./datensammlungen-import-export.md)
- [Datensammlungen in SQLite](./datensammlungen-sqlite.md)
