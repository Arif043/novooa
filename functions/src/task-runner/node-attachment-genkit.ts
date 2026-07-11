import {filesystem} from "@genkit-ai/middleware";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";

export function attachmentMiddleware(workspace?: NodeAttachmentWorkspace) {
  if (!workspace) return undefined;
  return [filesystem({rootDirectory: workspace.rootDirectory})];
}

export function attachmentInstructions(
  workspace?: NodeAttachmentWorkspace,
): string | undefined {
  if (!workspace) return undefined;
  const files = workspace.files
    .map((file) => `- ${file.filename} (${file.displayName})`)
    .join("\n");
  const notes = workspace.knowledgeFiles
    .map((note) => `- ${note.filename} (${note.title}, ${note.type})`)
    .join("\n");
  const parts = [
    "Angehängte Dateien und Wissensnotizen sind über die Dateisystem-Werkzeuge verfügbar.",
    "Nutze bei Bedarf list_files und read_file, um Inhalte zu prüfen.",
  ];
  if (files) parts.push(`Verfügbare Dateien:\n${files}`);
  if (notes) {
    parts.push([
      "Verfügbare Wissensnotizen:",
      notes,
      "MOC-Notizen wurden inklusive verlinkter Notizen bereitgestellt.",
      "Eine Übersicht liegt unter knowledge/manifest.json.",
    ].join("\n"));
  }
  return parts.join("\n");
}
