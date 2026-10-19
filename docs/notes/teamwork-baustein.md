# Baustein „Teamarbeit“

> Ein Orchestrator mit eigener Anweisung und eigenem Modell verteilt Aufträge an gewählte Mitarbeiter und liefert ein Ergebnis mit benannten, typisierten Feldern; nur Standalone.

Gehört zu: [Aufgabe](../index/aufgabe.md) · [Mitarbeiter](../index/mitarbeiter.md)

- **Primitive** `teamwork`, Konfiguration `TeamworkNodeConfig`:
  - `instruction`: Anweisung an den Orchestrator, mit Workflow-Werten (`{{…}}`) und Bildern wie beim Prompt-Baustein.
  - `languageModelId`: Modell des Orchestrators; leer bedeutet Standardmodell.
  - `members`: 1–5 Einträge, je `{employeeId, responsibility, languageModelId?}`, jeder Mitarbeiter höchstens einmal.
  - `outputFields`: die Felder des Ergebnisses.
  - `review`: `{enabled, languageModelId?}`, die Prüfung des Ergebnisses mit eigenem Modell; bei neuen Bausteinen an.
  - `attachments` und `knowledgeAttachments`: Anhänge wie beim Prompt-Baustein.
- **Zuständigkeit im Baustein:** `responsibility` steht beim Baustein, nicht beim [Mitarbeiter](./mitarbeiter.md), weil sie je Aufgabe verschieden ist. Sie ist Pflicht (höchstens 500 Zeichen) und wird die Beschreibung des Werkzeugs, nach der der Orchestrator Aufträge vergibt. Rahmenbedingung und Fähigkeiten kommen frisch vom Mitarbeiter.
- **Prüfung:** Ein eigenes Modell prüft das Ergebnis vor der Abgabe. So kann ein günstiges Modell orchestrieren und ein leistungsstärkeres prüfen. Bei Mängeln bessert der Orchestrator höchstens zweimal nach. Bleibt das Ergebnis beanstandet, wird es trotzdem geliefert, und die offenen Punkte stehen im Protokoll.
- **Aufträge und Gedächtnis:** Jeder Auftrag nennt, was zu tun ist, welches Ergebnis erwartet wird und was nicht dazugehört. Jeder Mitarbeiter erinnert sich an seine früheren Aufträge im selben Lauf. Die Mitarbeiter sprechen nur mit dem Orchestrator, nicht untereinander.
- **Feldtypen:**
  - `string`, `number`, `boolean`, `datetime`, `json`, wie beim [Prompt-Baustein](./prompt-executor.md);
  - `file` mit `fileFormat` (`markdown`, `csv`, `json`, `text`). Das Team schreibt die Datei, sie wird eine neue Team-Datei im Wurzelordner. Zunächst nur Textformate.
  - Jedes Feld ist ein eigener Workflow-Ausgabewert (`{{risiko}}`, `{{bericht}}`), ohne `value`.
- **Oberfläche** (`presentation/widgets/teamwork/`):
  - Anweisung und Modell des Orchestrators (Hinweis: Modelle mit Werkzeugaufrufen nötig);
  - Abschnitt „Team“ mit je einer Karte pro Mitarbeiter: Zuständigkeit, Modell, Entfernen; ein gelöschter Mitarbeiter wird angezeigt;
  - Abschnitt „Prüfung“ mit Schalter und eigenem Modell;
  - Abschnitt „Ergebnis“ mit dem gemeinsamen `StructuredOutputFieldsEditor` (Dateien mit Formatwahl);
  - Anhänge.
  - In der Palette nur, wenn es Mitarbeiter gibt (`employeesAvailable()`).
- **Fehlende Einstellungen:**
  - Ohne Mitarbeiter scheitert der Baustein mit `settingMissing` (`teamMembers`).
  - Ohne benanntes Feld scheitert er mit `settingMissing` (`resultFields`).
  - Ein gelöschter Mitarbeiter bricht den Lauf lesbar ab, wie beim Prompt-Baustein.

## Siehe auch

- [Ausführung der Teamarbeit](./teamwork-ausfuehrung.md)
- [Mitarbeiter](./mitarbeiter.md)
- [Multiagenten-Architektur des Aufgabenstudios](./multiagenten-aufgabenstudio.md)
