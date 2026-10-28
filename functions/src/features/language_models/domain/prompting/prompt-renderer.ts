import {type LlmPrompt} from "./llm-prompt.js";

/** Text des System- und Nutzerteils; ohne Systemabschnitte gibt es keinen Systemprompt. */
export type RenderedPrompt = {
  readonly system?: string;
  readonly user: string;
};

/**
 * Macht aus Abschnitten Text (Strategie). Aufrufstellen kennen nur Abschnitte, nicht das Format —
 * ein anderes Format braucht keine Änderung an ihnen.
 */
export interface PromptRenderer {
  render(prompt: LlmPrompt): RenderedPrompt;
}
