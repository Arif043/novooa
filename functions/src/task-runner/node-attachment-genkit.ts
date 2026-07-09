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
  return [
    "Angehängte Dateien sind über die Dateisystem-Werkzeuge verfügbar.",
    "Nutze bei Bedarf list_files und read_file, um Inhalte zu prüfen.",
    `Verfügbare Dateien:\n${files}`,
  ].join("\n");
}
