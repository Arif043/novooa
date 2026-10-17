import {type ModelArgument} from "genkit";
import {type GenkitBeta} from "genkit/beta";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

/** Alles, was ein einzelner Genkit-Aufruf eines Prompt-Bausteins braucht. */
export type PromptModelCall = {
  ai: GenkitBeta;
  model: ModelArgument;
  /** Anbieterspezifische Genkit-Konfiguration, aus den Generierungsoptionen übersetzt. */
  config: Record<string, unknown>;
  logContext: unknown;
  workspace?: NodeAttachmentWorkspace;
  logger: ApplicationLogger;
};
