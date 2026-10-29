import {type PreparedKnowledgeAttachment} from "../runner/knowledge-note-workspace.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {type ResolvedEmployee} from "../runner/task-definition.js";

/** Abschnitte, die mehrere Bausteine gleich formulieren — eine Stelle für den Wortlaut. */

const employeeHint = "Act as the employee described in <employee> and follow its instructions.";

/**
 * Rolle samt Verweis auf den Mitarbeiter — nur, wenn er eine Rahmenbedingung hat; ohne sie gibt es
 * keinen `<employee>`-Abschnitt, auf den die Rolle zeigen könnte.
 */
export function roleWithEmployee(role: string, employee: ResolvedEmployee | undefined): string {
  return employee?.constraint.trim() ? `${role} ${employeeHint}` : role;
}
/** Welche Anhänge über die Dateisystem-Werkzeuge erreichbar sind und wie man sie liest. */
export function attachmentsSectionFor(workspace?: NodeAttachmentWorkspace): string | undefined {
  if (!workspace) return undefined;
  const files = workspace.files.map((file) => `- ${file.filename} (${file.displayName})`);
  return [
    "Attached files and knowledge notes are available through the file system tools. Use list_files and read_file to inspect them when needed.",
    files.length > 0 ? `Available files:\n${files.join("\n")}` : "",
    knowledgeNotesOverview(workspace.knowledgeFiles),
    workspace.skillCount > 0 ? "Skills are available through the use_skill tool. Use a suitable skill before you answer." : "",
  ].filter(Boolean).join("\n\n");
}

/**
 * Alle Notizen im Workspace samt ihren Links, damit das Modell den Zusammenhang kennt, ohne erst
 * `knowledge/manifest.json` zu lesen. Die Dateinamen tragen den Titel, `[[Titel]]` führt direkt zur Datei.
 */
function knowledgeNotesOverview(notes: readonly PreparedKnowledgeAttachment[]): string {
  if (notes.length === 0) return "";
  return [
    "Knowledge notes in the workspace: the attached notes and the notes they link to, directly or indirectly. "
      + "Each file is named after the note's title, so a wiki link [[Title]] refers to knowledge/Title.md. "
      + "Read the attached notes first and follow their links when they matter for the task.",
    ...notes.map(overviewLine),
  ].join("\n");
}

function overviewLine(note: PreparedKnowledgeAttachment): string {
  const role = note.isDirectAttachment ? "attached" : `linked, level ${note.depth}`;
  const links = note.linkedTitles.length > 0 ? `; links to: ${note.linkedTitles.join(", ")}` : "";
  return `- ${note.filename} (${role}${links})`;
}
