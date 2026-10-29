# Links zwischen Wissensnotizen

> Notizen verlinken sich wie in Obsidian über `[[Ziel]]` oder Markdown-Links; ein Ziel darf Titel, ID, Pfad oder Pfad ohne `.md` sein.

Gehört zu: [Wissensbasis](../index/wissensbasis.md)

- `[[Ziel]]`, `[[Ziel|Anzeigetext]]`, `[Text](leitfaden.md)`.
- `[[Ziel#Abschnitt]]` löst die Notiz `Ziel` auf; der Abschnitt wirkt in der
  Einzelnotiz-Ansicht noch nicht.
- Die Zuordnung „Linkziel → Notiz“ liegt im Domain-Service
  `KnowledgeNoteResolver`; `MarkdownLinkExtractor` nutzt ihn für Graph und
  Backlinks.
- ID-Links überstehen Umbenennungen; Titel- und Pfadlinks lösen gegen die
  aktuellen Aliase auf. Unbekannte Ziele ergeben keine ID, Mehrfachlinks
  werden zusammengefasst.
- Titel sind pro Wissensbasis eindeutig, ohne Unterschied von Groß/Klein;
  `[[Titel]]` trifft deshalb genau eine Notiz. Die Runtime lehnt einen
  vergebenen Titel mit 409 `duplicate_title` ab, der Client speichert ihn gar
  nicht erst; Migration 0032 sichert das mit einem eindeutigen Index ab.
- `outgoingLinks` entstehen in der Bearbeitungsvorschau des Clients und in
  SQLite beim Lesen (`knowledgeLinksFrom`, für API und Runs).

## Siehe auch

- [Wissenslinks werden beim Lesen berechnet (0019)](./sqlite-wissenslinks-berechnet.md)
- [Lesen-Ansicht der Wissensbasis](./wissensbasis-lesen-ansicht.md)
- [Wissensgraph](./wissensgraph.md)
