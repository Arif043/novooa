# Datenbank-Seite

> Die Seite „Datenbank“ zeigt Sammlungen als Excel-artige Arbeitsblätter: Sammlungen anlegen, umbenennen, leeren und löschen; Datensätze anlegen, bearbeiten, sortieren, auswählen und gemeinsam löschen; Import und Export als CSV oder JSON.

Gehört zu: [Daten](../index/daten.md)

- **Übersicht** im [Luminous-Seitenstil](./luminous-seitenstil.md) wie der
  Zeitplan: Kopf „Datenbank“ mit Untertitel, Zusammenfassung („3 Sammlungen ·
  128 Datensätze“) und „Sammlung anlegen“; ab zwei Sammlungen eine Suche über
  Namen und Feldnamen; je Sammlung eine Karte mit Tabellensymbol, Name,
  Feldvorschau (vier Felder, dann „+n“), Anzahl, „geändert vor …“ und Menü
  (⋯: Import, Export, Umbenennen, Leeren, Löschen). Antippen öffnet das Blatt.
  Ohne Sammlungen ein leerer Zustand mit „Sammlung anlegen“. Sammlungen
  entstehen weiterhin auch automatisch, wenn ein Arbeitsplan hineinschreibt.
- Feldvorschau und letzte Änderung liefert die Runtime je Sammlung aus den 50
  jüngsten Datensätzen (`fields`, `changedAt`); ab einer Woche steht ein Datum.
- **Blatt einer Sammlung:** Brotkrume „‹ Datenbank“, derselbe Seitenkopf mit
  Name, Anzahl und letzter Änderung, „Datensatz anlegen“ und dem Menü —
  seltene Aktionen bewusst im Menü (Hick's Law).
- Darstellung des Blatts: ruhige Tabelle ohne Spaltenbuchstaben; jeder
  Spaltenkopf zeigt ein Symbol für die Art seiner Werte (Zahl, Wahrheitswert,
  Text, Struktur). Zahlen rechtsbündig mit Ziffern gleicher Breite und im
  Zahlenformat der Sprache, Wahrheitswerte als Etikett „Ja“/„Nein“, leere
  Werte als gedämpftes „—“, Strukturen gedämpft. Zeilennummern gedämpft,
  feste Kopfzeile, horizontaler Bildlauf; Sammlungsreiter wechseln das Blatt.
  Zeilen öffnen den Editor — keine direkte Zellbearbeitung. Zeilen werden beim
  Scrollen bedarfsgerecht aufgebaut.
- Die obere Leiste der App zeigt keinen Titel; er steht im Seitenkopf.
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
- Filter, Editor und Kopf brechen bei schmalen Fenstern oder großer Schrift
  um; bei wenig Höhe scrollt das Blatt als Ganzes (Mindesthöhe 640, wächst
  mit der Schriftgröße).
- Aufbau: `DatabaseCubit` (Laden, Suche, Filter, Sortierung, Auswahl,
  einzelne Datensätze), `DatabaseActionsCubit` (Sammlungen, Mehrfachlöschen,
  Export) und `DatabaseImportCubit` (Datei → Vorschau → übernehmen).
  Rückmeldungen als Snackbar, Texte über `LocaleKeys` (`ui.db_*`).
- Stil „Luminous Precision“.

## Siehe auch

- [Import und Export von Datensammlungen](./datensammlungen-import-export.md)
- [Datensammlungen in SQLite](./datensammlungen-sqlite.md)
