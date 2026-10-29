/** Höchstlänge eines Dateinamens ohne `.md`; hält Pfade auch unter Windows kurz genug. */
const maximumNameLength = 120;

type NamedNote = {noteId: string; title: string; path: string};

/**
 * Workspace-Dateiname je Notiz: der Titel, damit `[[Titel]]` im Markdown direkt auf die Datei
 * zeigt. Titel sind in der Wissensbasis eindeutig, deshalb braucht es keinen Zusatz.
 */
export function knowledgeNoteFilenames(notes: readonly NamedNote[]): Map<string, string> {
  return new Map(notes.map((note) => [note.noteId, `knowledge/${baseNameOf(note)}.md`]));
}

function baseNameOf(note: NamedNote): string {
  const fromPath = note.path.split("/").pop() ?? "";
  return safeName(note.title) || safeName(fromPath) || safeName(note.noteId) || "Notiz";
}

/** Entfernt, was in Dateinamen verboten ist oder Pfade verlässt; Umlaute und Leerzeichen bleiben. */
function safeName(value: string): string {
  return value
    .replace(/\.md$/i, "")
    // eslint-disable-next-line no-control-regex
    .replace(/[/\\:*?"<>|\u0000-\u001f]+/g, "-")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/^[.\s]+|[.\s]+$/g, "")
    .slice(0, maximumNameLength)
    .trim();
}
