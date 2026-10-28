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
  const notes = workspace.knowledgeFiles
    .filter((note) => note.isDirectAttachment)
    .map((note) => `- ${note.filename} (${note.title})`);
  return [
    "Attached files and knowledge notes are available through the file system tools. Use list_files and read_file to inspect them when needed.",
    files.length > 0 ? `Available files:\n${files.join("\n")}` : "",
    notes.length > 0 ? knowledgeNotesHint(notes) : "",
    workspace.skillCount > 0 ? "Skills are available through the use_skill tool. Use a suitable skill before you answer." : "",
  ].filter(Boolean).join("\n\n");
}

function knowledgeNotesHint(notes: string[]): string {
  return [
    "Directly attached knowledge notes:",
    ...notes,
    "Use exactly these paths when reading knowledge notes. Linked notes are in the workspace as well: follow the links from the attached note; knowledge/manifest.json lists them all.",
  ].join("\n");
}
