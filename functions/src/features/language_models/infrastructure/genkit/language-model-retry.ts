import {GenkitError, type GenerateRequest, type GenerateResponseData} from "genkit";
import {LanguageModelError, ModelProviderUnavailableError} from "../errors/language-model-errors.js";

/** Genkits einfache Modell-Middleware, in `use` von `ai.generate` erlaubt. */
export type LanguageModelMiddleware = (
  request: GenerateRequest, next: (request?: GenerateRequest) => Promise<GenerateResponseData>,
) => Promise<GenerateResponseData>;

export interface LanguageModelRetryPolicy {
  readonly maxRetries: number;
  readonly initialDelayMs: number;
  readonly backoffFactor: number;
  readonly wait: (delayMs: number) => Promise<void>;
}

export const defaultLanguageModelRetryPolicy: LanguageModelRetryPolicy = {
  maxRetries: 3,
  initialDelayMs: 1000,
  backoffFactor: 2,
  wait: (delayMs) => new Promise((resolve) => setTimeout(resolve, delayMs)),
};

// Zeitüberschreitungen fehlen absichtlich: Ein langsames lokales Modell ist
// beim nächsten Versuch genauso langsam und blockiert den Lauf nur länger.
const retryableGenkitStatuses = new Set<string>(["UNAVAILABLE", "RESOURCE_EXHAUSTED", "ABORTED", "INTERNAL"]);

/**
 * Wiederholt einen Modellaufruf nur bei vorübergehenden Fehlern. Genkits
 * `retry` wiederholt jeden Fehler außer `GenkitError`, also auch unsere
 * eindeutigen Fehler wie eine abgeschnittene Antwort.
 */
export function languageModelRetry(policy = defaultLanguageModelRetryPolicy): LanguageModelMiddleware {
  return async (request, next) => {
    for (let attempt = 0; ; attempt++) {
      try {
        return await next(request);
      } catch (error) {
        if (attempt >= policy.maxRetries || !isRetryableModelError(error)) throw error;
        await policy.wait(policy.initialDelayMs * policy.backoffFactor ** attempt);
      }
    }
  };
}

export function isRetryableModelError(error: unknown): boolean {
  if (error instanceof LanguageModelError) return error instanceof ModelProviderUnavailableError;
  if (error instanceof GenkitError) return retryableGenkitStatuses.has(error.status);
  return !(error instanceof Error && error.name === "AbortError");
}
