# Mitarbeiter-Seite

> Route `/employees` listet Mitarbeiter mit Name, Rahmenbedingung und Anzahl der Fähigkeiten; bearbeitet wird in einem adaptiven Sheet.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md)

- Layout im [Luminous-Seitenstil](./luminous-seitenstil.md) wie der
  Zeitplan: Kopf mit Titel, Untertitel, Anzahl und „Mitarbeiter anlegen“, je
  Mitarbeiter eine `EmployeeCard` mit Avatar (Noovi im Ring seiner Farbe),
  Name, Rahmenbedingung (höchstens drei Zeilen) und in der Fußzeile die Zahl
  der Fähigkeiten, Bearbeiten und Löschen.
- Antippen der Karte oder der Stift öffnet den Editor; Löschen mit Bestätigung
  und Hinweis auf betroffene Bausteine.
- Ohne Mitarbeiter: `EmployeesEmptyState` nach dem
  [Muster für leere Zustände](./leerer-zustand-muster.md), mit winkendem Noovi
  statt Symbol.
- Editor: *Name*, *Rahmenbedingung* („Gilt als System-Prompt für jeden
  Aufruf.“), *Fähigkeiten* aus den vorhandenen Skills; nicht mehr vorhandene
  Namen bleiben als „Nicht mehr vorhanden“ sichtbar und entfernbar.
- Zustände Laden, Fehler (mit „Erneut versuchen“), Leer, Erfolg; alle Texte
  über `LocaleKeys` (`ui.employees_*`, `ui.employee_*`).
- **Transfer:** Bereich **Mitarbeiter** zwischen Fähigkeiten und Aufgaben.
  Gleiche IDs werden überschrieben; gleicher Name unter anderer ID bekommt
  „ (2)“. Fehlende Fähigkeiten im Ziel meldet erst der Lauf.

## Siehe auch

- [Mitarbeiter](./mitarbeiter.md)
- [Import/Export](../index/import-export.md)
