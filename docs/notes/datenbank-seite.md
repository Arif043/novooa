# Datenbank-Seite

> Die Seite „Datenbank“ (nur Standalone) zeigt die von Arbeitsplänen angelegten Sammlungen als Excel-artige Arbeitsblätter; Datensätze lassen sich anlegen, bearbeiten und löschen.

Gehört zu: [Daten](../index/daten.md)

- Nur Sammlungen, die durch einen Arbeitsplan entstanden sind; kein manuelles
  Anlegen, Umbenennen oder Löschen von Sammlungen.
- Darstellung: Spaltenbuchstaben, Zeilennummern, Zellraster, feste
  Kopfzeile, horizontaler Bildlauf; Sammlungsreiter wechseln das Blatt.
  Zeilen öffnen den Editor — keine direkte Zellbearbeitung. Zeilen werden beim
  Scrollen bedarfsgerecht aufgebaut.
- Suche über alle skalaren Feldwerte; strukturierte Filter (Feld, Vergleich,
  Wert) gehen an die Runtime.
- Die technische Datensatz-ID erscheint nicht in der Oberfläche.
- Editor: Werte werden als Zahl oder Boolean erkannt, sonst Text;
  verschachtelte Werte als gültiges JSON bearbeitbar.
- Filter und Editor brechen bei schmalen Fenstern oder großer Schrift um.
- Stil „Luminous Precision“.

## Siehe auch

- [Datensammlungen in SQLite](./datensammlungen-sqlite.md)
