# Wissensnotizen als Anhang

> Bausteine hängen Notizen wie Dateien an; beim Run lädt das Backend die Notiz und ihre verlinkten Notizen per Breitensuche in den Workspace.

Gehört zu: [Wissensbasis](../index/wissensbasis.md)

Unterstützte Node-Configs speichern `knowledgeAttachments` neben
`attachments`, nur als Referenz:

```json
{"knowledgeBaseId": "default", "noteId": "note.1", "title": "Index", "path": "index.md"}
```

- Beim Run landen angehängte Notizen und ihre direkten und indirekten Links
  unter `knowledge/` im Genkit-Workspace.
- Breitensuche: erst die Anhänge, dann deren Links, dann deren Links. Ende nach
  5 Ebenen bzw. 50 Notizen; am Limit fallen die entferntesten weg.
  Der Client bildet dieselben Regeln in `KnowledgeNoteReach` nach, um im
  [Wissensgraph](./wissensgraph.md) den Prompt-Kontext einer Notiz zu zeigen;
  Grenzen bitte an beiden Stellen ändern.
- Jede Notiz liegt als `knowledge/<Titel>.md` im Workspace; weil Titel
  eindeutig sind, führt `[[Titel]]` direkt zur Datei. Verbotene Zeichen im
  Dateinamen werden ersetzt (`knowledge-note-filenames.ts`).
- Der Prompt listet alle eingesammelten Notizen mit Rolle (angehängt bzw.
  verlinkt, Ebene) und den Titeln, auf die sie verlinken
  (`attachmentsSectionFor`); `knowledge/manifest.json` gibt es zusätzlich.
- Prompt-Bausteine sind angebunden, Script-Bausteine bewusst noch nicht.

## Siehe auch

- [Anhänge und Workspace](./anhaenge-workspace.md)
- [Links zwischen Wissensnotizen](./wissenslinks-syntax.md)
