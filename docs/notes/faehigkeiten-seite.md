# Fähigkeiten-Seite

> Die Seite Fähigkeiten zeigt die Skills des Skills-Ordners im Luminous-Seitenstil des Zeitplans: Kopf mit Import, eine Karte je Fähigkeit, eigener leerer Zustand.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

- `SkillsPage` (`lib/features/skills/presentation/pages/skills_page.dart`)
  im [Luminous-Seitenstil](./luminous-seitenstil.md): mittige Spalte über
  `PageInsets`, Kopf `LuminousPageHeader` mit Titel, Untertitel, Anzahl der
  Fähigkeiten und „Importieren“ als Hauptaktion
  ([Skills importieren](./skills-import.md)).
- Je Fähigkeit eine `SkillCard`: Symbol, Name und Beschreibung (höchstens drei
  Zeilen), Warnungen des Ordners, in der Fußzeile Dateizahl und Lizenz, rechts
  Löschen mit Rückfrage.
- Ohne Fähigkeiten: `SkillsEmptyState` nach dem
  [Muster für leere Zustände](./leerer-zustand-muster.md) mit „Fähigkeiten
  importieren“. Laden und Fehler (mit „Erneut versuchen“) stehen unter dem
  Kopf.
- Alle Texte über `LocaleKeys` (`ui.skills_*`, `ui.skill_*`).

## Siehe auch

- [Skills-Ordner](./skills-ordner.md)
- [Zeitplan-Seite](./zeitplan-seite.md)
