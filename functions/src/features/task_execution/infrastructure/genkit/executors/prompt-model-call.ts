import {type ModelArgument} from "genkit";
import {type GenkitBeta} from "genkit/beta";
import {type LlmGateway} from "../../../../language_models/domain/prompting/llm-gateway.js";
import {type GenkitLlmBinding} from "../../../../language_models/infrastructure/genkit/llm/genkit-llm-binding.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {aiTurnMiddleware} from "../runner/node-attachment-genkit.js";

/** Alles, was ein einzelner Modellaufruf eines Prompt-Bausteins braucht. */
export type PromptModelCall = {
  ai: GenkitBeta;
  model: ModelArgument;
  /** Anbieterspezifische Genkit-Konfiguration, aus den Generierungsoptionen übersetzt. */
  config: Record<string, unknown>;
  logContext: unknown;
  workspace?: NodeAttachmentWorkspace;
  /** LLM-Framework: rendert den Prompt, protokolliert und übersetzt Fehler. */
  gateway: LlmGateway<GenkitLlmBinding>;
};

/** Modell und Werkzeuge des Aufrufs; die Middleware bringt Retry, Dateisystem und Skills mit. */
export function bindingFor(call: PromptModelCall): GenkitLlmBinding {
  const {ai, model, config, logContext, workspace} = call;
  return {ai, model, config, logContext, use: aiTurnMiddleware(workspace)};
}
