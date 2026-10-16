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
- Der Prompt nennt nur die direkt angehängte Notiz; verlinkte entdeckt das
  Modell über die Links im Markdown und `knowledge/manifest.json`.
- Prompt-Bausteine sind angebunden, Script-Bausteine bewusst noch nicht.

## Siehe auch

- [Anhänge und Workspace](./anhaenge-workspace.md)
- [Links zwischen Wissensnotizen](./wissenslinks-syntax.md)
