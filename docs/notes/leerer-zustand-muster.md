# Muster für leere Zustände

> Eine Seite ohne Inhalt zeigt zentriert Symbol, Titel, Erklärung und genau eine primäre Aktion.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Vorbild ist die Wissensbasis; Zeitplan (`ScheduleEmptyState`) und Dateien
(`FilesInitialState`) folgen demselben Aufbau:

- Symbol (Größe 48)
- Titel in `titleLarge`
- Erklärung in `bodyLarge`
- ein `FilledButton` als einzige Aktion (Hick's Law: eine klare Wahl)
- Breite höchstens 480 px (`ConstrainedBox`), Abstand `AppSpacing.xl`

Sobald der erste Eintrag existiert, wechselt die Seite in ihre Listenansicht.
Ein leerer Unterordner ist kein „leerer Zustand“ in diesem Sinn und zeigt nur
einen Hinweis in der Liste.

## Siehe auch

- [Luminous-Seitenstil](./luminous-seitenstil.md)
- [Zeitplan-Seite](./zeitplan-seite.md)
