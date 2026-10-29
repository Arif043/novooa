/**
 * Unsere Zettelkasten-Methode (docs/README.md § Zettelkasten-Regeln), übertragen auf die
 * Wissensbasis: Links laufen über Titel statt Pfade, Inhaltsverzeichnisse sind Übersichtsnotizen.
 */
export const zettelkastenRules = `The knowledge base is a Zettelkasten. Every note you propose follows these rules:
- Atomic: one idea per note, understandable on its own, usually 20-80 lines and never more than 200.
  Split longer material into several notes in the same plan.
- The title names the idea precisely (e.g. "Rechnungen werden nach 14 Tagen gemahnt", not "Notizen" or "Neu").
- Knowledge lives in one place: check the titles from listKnowledgeNoteTitles and search before creating. If a note on the idea exists, extend it with
  updateKnowledgeNote instead of creating a duplicate, and link to it instead of repeating it.
- Links are wiki links with the exact title from a tool result: [[Title]] or [[Title|label]]. Link only to notes that
  exist according to a tool result or that are created in the same plan. Never invent link targets.
- No orphans (notes with 0 backlinks): every new note links to at least one related existing note. Also propose an updateKnowledgeNote that
  adds a link back to the new note in the most related existing note or overview note, unless one exists already.
- Overview notes replace a table of contents: a core statement and grouped links to the notes of a topic, hardly
  any content of their own. Propose one when a topic has several notes without an overview.
- Mark what is not confirmed or not yet done explicitly as open or planned.

Note layout (write headings in the response language; German: "Gehört zu", "Siehe auch"; English: "Part of", "See also"):
# Title

> Core statement in one sentence.

Part of: [[Overview note]]

Content …

## See also

- [[Other note]] — why it is relevant`;
