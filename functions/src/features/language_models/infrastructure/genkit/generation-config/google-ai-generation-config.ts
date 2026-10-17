import {type GenerationOptions, type ThinkingMode} from "../../../domain/entities/generation-options.js";
import {definedEntries, type GenkitGenerationConfig} from "./genkit-generation-config.js";

type ThinkingConfig = {thinkingBudget?: number; thinkingLevel?: "MINIMAL" | "LOW" | "MEDIUM" | "HIGH"};

/** Budgets aus Googles Zuordnung von `reasoning_effort` zu `thinking_budget` (Gemini 2.5). */
const thinkingBudgets = {low: 1024, medium: 8192, high: 24576} as const;

/**
 * Gemini 2.5 steuert Nachdenken per Budget, Gemini 3 per Stufe; beides zusammen lehnt die API ab.
 * Das Kontextfenster ist bei Gemini fest und wird ignoriert.
 */
export function googleAiGenerationConfig(modelId: string): GenkitGenerationConfig {
  const thinkingFor = usesThinkingBudget(modelId) ? budgetThinking : leveledThinking(modelId);
  return {
    configFor(options: GenerationOptions): Record<string, unknown> {
      return definedEntries({
        temperature: options.temperature?.value,
        maxOutputTokens: options.maxOutputTokens?.value,
        thinkingConfig: thinkingFor(options.thinking),
      });
    },
  };
}

function usesThinkingBudget(modelId: string): boolean {
  return /^gemini-(1|2)\./.test(modelId);
}

function budgetThinking(mode: ThinkingMode): ThinkingConfig | undefined {
  if (mode === "modelDefault") return undefined;
  return {thinkingBudget: mode === "off" ? 0 : thinkingBudgets[mode]};
}

/** Gemini 3 lässt sich nicht ganz abschalten; `MINIMAL` kommt dem am nächsten, Pro kennt es nicht. */
function leveledThinking(modelId: string): (mode: ThinkingMode) => ThinkingConfig | undefined {
  const lowest = /pro/.test(modelId) ? "LOW" : "MINIMAL";
  return (mode) => {
    if (mode === "modelDefault") return undefined;
    if (mode === "off") return {thinkingLevel: lowest};
    return {thinkingLevel: mode.toUpperCase() as "LOW" | "MEDIUM" | "HIGH"};
  };
}
