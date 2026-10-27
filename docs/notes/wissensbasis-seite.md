# Wissensbasis-Seite

> Eine Obsidian-artige Arbeitsfläche: links Notizliste, Mitte Dokument mit Schreiben/Lesen/Graph, rechts Eigenschaften und Links; gespeichert wird automatisch.

Gehört zu: [Wissensbasis](../index/wissensbasis.md)

Route `/knowledge-base`, Drawer-Label **Wissensbasis**, Designsystem
„Luminous Precision“.

- **Links:** Notizliste mit Suche, Inhaltsvorschau, „Notiz erstellen“.
- **Mitte:** Dokument mit „Schreiben“, „Lesen“, „Graph“; der Graph füllt den
  Bereich als Leinwand mit eckigen oberen Ecken. Kein Speicherstatus im
  Dokument — Fehler beim Speichern meldet eine Snackbar. Die Ansichten sind Symbolknöpfe links
  (`KnowledgeBaseModeToolbar`, Bezeichnung im Tooltip, die gewählte getönt),
  „Notiz löschen“ steht rechts.
- **Rechts:** Eigenschaften, Speicherstatus, verlinkte Notizen, Backlinks.
- Änderungen speichert ein Debounce automatisch; kein Speichern-Button.
- Kleine Displays oder große Schrift: Einspaltenansicht mit „Alle Notizen“;
  die Symbolknöpfe passen auch dort, ein Auswahlfeld ist nicht nötig.
- Löschen verlangt eine Bestätigung.
- Ohne Notizen: zentrierter Einstieg — Vorbild des
  [Musters für leere Zustände](./leerer-zustand-muster.md).

## Siehe auch

- [Lesen-Ansicht der Wissensbasis](./wissensbasis-lesen-ansicht.md)
- [Wissensgraph](./wissensgraph.md)
- [Wissensbasis-Agent](./wissensbasis-agent.md)
