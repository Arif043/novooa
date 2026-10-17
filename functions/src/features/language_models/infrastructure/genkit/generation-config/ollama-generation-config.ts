import {type GenerationOptions, type ThinkingMode} from "../../../domain/entities/generation-options.js";
import {type OllamaGenkitConfig} from "../../ollama/native-ollama-genkit-plugin.js";
import {definedEntries, type GenkitGenerationConfig} from "./genkit-generation-config.js";

/** Ollama kennt alle Optionen, auch das Kontextfenster (`num_ctx`). */
export const ollamaGenerationConfig: GenkitGenerationConfig = {
  configFor(options: GenerationOptions): Record<string, unknown> {
    const config: OllamaGenkitConfig = {
      temperature: options.temperature?.value,
      maxOutputTokens: options.maxOutputTokens?.value,
      numCtx: options.contextWindow?.value,
      think: ollamaThinkingFor(options.thinking),
    };
    return definedEntries(config);
  },
};

/** Stufen versteht nur ein Teil der Modelle (z. B. gpt-oss); die übrigen behandeln sie wie `true`. */
function ollamaThinkingFor(mode: ThinkingMode): OllamaGenkitConfig["think"] {
  if (mode === "modelDefault") return undefined;
  if (mode === "off") return false;
  return mode;
}
