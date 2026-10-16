# Lesen-Ansicht der Wissensbasis

> „Lesen“ rendert die Notiz als GitHub-Flavored Markdown mit Wiki-Links, Formeln und Markierungen; Gestaltung kommt ganz aus dem Theme.

Gehört zu: [Wissensbasis](../index/wissensbasis.md)

- `flutter_markdown_plus` (`KnowledgeMarkdownPreview`): Überschriften,
  fett, kursiv, durchgestrichen, Listen inklusive Aufgabenlisten, Tabellen,
  Zitate, Code, Linien, Bilder, Autolinks, Emoji-Kürzel (`:smile:`). Text ist
  markierbar.
- `[[Ziel]]` und `[[Ziel|Text]]` werden über `KnowledgeWikiLinkSyntax` zu
  Links; ohne passende Notiz bleiben sie Text. Markdown-Links auf Notizen öffnen
  ebenfalls die Notiz.
- `http`, `https`, `mailto` öffnen extern (`KnowledgeMarkdownLinkHandler`),
  andere Schemata werden ignoriert.
- **Formeln** (`flutter_math_fork`): `$…$` inline, `$$…$$`, mehrzeilige
  `$$`-Blöcke und `\[…\]` abgesetzt. Wie in Obsidian/Pandoc kein Leerzeichen
  direkt innerhalb der `$` und keine Ziffer nach dem schließenden `$` — „5 $
  bis 10 $“ bleibt Text. Fehlerhafte Formeln erscheinen als roter Quelltext.
- **Markierung** `==Text==` mit dem Akzent des Themes; Formatierung darin wird
  nicht zusätzlich gerendert.
- Stil: `KnowledgeMarkdownStyleSheet`. Leere Notizen verweisen auf „Schreiben“.

## Siehe auch

- [Links zwischen Wissensnotizen](./wissenslinks-syntax.md)
- [Wissensbasis-Seite](./wissensbasis-seite.md)
