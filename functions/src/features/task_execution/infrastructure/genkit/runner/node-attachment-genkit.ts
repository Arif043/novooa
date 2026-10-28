import {filesystem, skills} from "@genkit-ai/middleware";
import {type GenerateOptions} from "genkit";
import {languageModelRetry} from "../../../../language_models/infrastructure/genkit/language-model-retry.js";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";

/** Retry immer; mit Arbeitsordner Dateisystem-Werkzeuge, mit Fähigkeiten zusätzlich `use_skill`. */
export function aiTurnMiddleware(workspace?: NodeAttachmentWorkspace): NonNullable<GenerateOptions["use"]> {
  const middleware: NonNullable<GenerateOptions["use"]> = [languageModelRetry()];
  if (workspace) {
    middleware.push(filesystem({rootDirectory: workspace.rootDirectory}));
    if (workspace.skillsDirectory) {
      middleware.push(skills({skillPaths: [workspace.skillsDirectory]}));
    }
  }
  return middleware;
}
