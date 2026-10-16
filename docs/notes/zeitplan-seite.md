# Zeitplan-Seite

> Ohne Auslöser zeigt „Zeitplan“ einen zentrierten Einstieg, ab dem ersten Auslöser eine Kartenliste.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Code: `lib/features/schedule/presentation/pages/schedule_page.dart`.

- **Leer:** `ScheduleEmptyState` nach dem
  [Muster für leere Zustände](./leerer-zustand-muster.md) mit der Aktion
  „Ersten Auslöser erstellen“.
- **Mit Auslösern:** Titel und Button „Auslöser hinzufügen“ in einer Zeile,
  darunter Untertitel und „n aktiv · m pausiert“. Darunter eine scrollbare
  Liste höhenflexibler Karten im [Luminous-Seitenstil](./luminous-seitenstil.md).

Jede Karte zeigt:

- Aufgabe
- Regel, z. B. „Datei erstellt · Berichte / 2026 (mit Unterordnern) · Bilder“
- Schalter Aktiv/Pausiert
- nächste Ausführung
- Löschen mit Bestätigung (die Aufgabe bleibt erhalten)

Lade- und Fehlerzustände sowie Hell- und Dunkelmodus sind berücksichtigt.

## Siehe auch

- [Dialog „Auslöser hinzufügen“](./ausloeser-dialog.md)
