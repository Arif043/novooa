# Mitarbeiter-Seite

> Route `/employees` listet Mitarbeiter mit Name, Rahmenbedingung und Anzahl der Fähigkeiten; bearbeitet wird in einem adaptiven Sheet.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md)

- Liste mit gekürzter Rahmenbedingung; Löschen mit Bestätigung und Hinweis auf
  betroffene Bausteine.
- Editor: *Name*, *Rahmenbedingung* („Gilt als System-Prompt für jeden
  Aufruf.“), *Fähigkeiten* aus den vorhandenen Skills; nicht mehr vorhandene
  Namen bleiben als „Nicht mehr vorhanden“ sichtbar und entfernbar.
- Zustände Laden, Fehler, Leer, Erfolg.
- **Transfer:** Bereich **Mitarbeiter** zwischen Fähigkeiten und Aufgaben.
  Gleiche IDs werden überschrieben; gleicher Name unter anderer ID bekommt
  „ (2)“. Fehlende Fähigkeiten im Ziel meldet erst der Lauf.

## Siehe auch

- [Mitarbeiter](./mitarbeiter.md)
- [Import/Export](../index/import-export.md)
