import {type GenerationOptions, type ThinkingMode} from "../../../domain/entities/generation-options.js";
import {definedEntries, type GenkitGenerationConfig} from "./genkit-generation-config.js";

/**
 * OpenAI-kompatible Anbieter (xAI, Mistral, OpenRouter, …). Das Genkit-Plugin verwirft
 * `maxOutputTokens`, reicht unbekannte Felder aber durch; deshalb `max_tokens` direkt.
 * Ein abschaltbares Nachdenken gibt es dort nicht einheitlich; `off` bleibt ohne Wirkung.
 */
export const openAiCompatibleGenerationConfig: GenkitGenerationConfig = {
  configFor(options: GenerationOptions): Record<string, unknown> {
    return definedEntries({
      temperature: options.temperature?.value,
      max_tokens: options.maxOutputTokens?.value,
      reasoning_effort: reasoningEffortFor(options.thinking),
    });
  },
};

function reasoningEffortFor(mode: ThinkingMode): "low" | "medium" | "high" | undefined {
  return mode === "modelDefault" || mode === "off" ? undefined : mode;
}
