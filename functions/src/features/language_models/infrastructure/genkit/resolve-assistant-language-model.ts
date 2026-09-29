import {genkit, type Genkit, type ModelArgument} from "genkit";
import {
  aiProviderPlugins,
  textModel,
} from "../../../task_execution/infrastructure/genkit/runner/ai-models.js";
import {type GenkitLanguageModelResolver} from "./genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

export type AssistantLanguageModel = {ai: Genkit; model: ModelArgument};

/**
 * Löst das für den KI-Agenten konfigurierte Sprachmodell auf — dieselbe
 * Vorgabe-Logik wie für Sprachmodell-Bausteine (siehe
 * `genkit-prompt-executor.ts`s `defaultLanguageModelFor`), nur ohne den
 * "explizit gewählt"-Zweig, den der Assistent nicht kennt. Ohne Treffer
 * (nichts konfiguriert, oder die Vorgabe zeigt auf ein gelöschtes Modell)
 * bleibt der bisherige umgebungsvariablen-gesteuerte Standardmodell-Pfad
 * aktiv. Wird pro Anfrage aufgerufen (siehe Aufrufer), damit eine geänderte
 * Vorgabe ohne Neustart wirkt.
 */
export async function resolveAssistantLanguageModel(
  teamId: string,
  resolver: GenkitLanguageModelResolver,
  defaultsStore: LanguageModelDefaultsStore,
): Promise<AssistantLanguageModel> {
  const defaults = await defaultsStore.loadDefaults(teamId);
  if (defaults.assistantModelId) {
    try {
      const resolved = await resolver.resolve(teamId, defaults.assistantModelId);
      return {ai: resolved.ai, model: resolved.model};
    } catch {
      // Vorgabe zeigt auf ein gelöschtes Modell — Rückfall auf Standardmodell.
    }
  }
  return {ai: genkit({plugins: aiProviderPlugins()}), model: textModel()};
}
