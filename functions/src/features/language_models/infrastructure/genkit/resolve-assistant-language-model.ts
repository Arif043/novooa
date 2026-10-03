import {googleAI} from "@genkit-ai/google-genai";
import {genkit, type Genkit, type ModelArgument} from "genkit";
import {
  aiProviderPlugins,
  textModel,
} from "../../../task_execution/infrastructure/genkit/runner/ai-models.js";
import {type AssistantModelSettings} from "../../domain/repositories/assistant-model-settings.js";

export type AssistantLanguageModel = {ai: Genkit; model: ModelArgument};

/**
 * Das Sprachmodell des KI-Agenten legt die Cloud fest, nicht der Nutzer: Ist
 * in den [settings] (Remote Config) ein Google-Modell hinterlegt, gilt es;
 * sonst — und in der lokalen Runtime, die keine Remote Config kennt — das
 * Standardmodell aus `ai-models.ts`. Wird pro Anfrage aufgerufen, damit eine
 * geänderte Einstellung ohne Neustart wirkt (die Einstellung cached selbst).
 */
export async function resolveAssistantLanguageModel(
  settings?: AssistantModelSettings,
): Promise<AssistantLanguageModel> {
  const name = await settings?.modelName() ?? null;
  const ai = genkit({plugins: aiProviderPlugins()});
  return {ai, model: name === null ? textModel() : googleAI.model(name)};
}
