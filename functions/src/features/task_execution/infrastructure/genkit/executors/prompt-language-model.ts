import {
  type GenkitLanguageModelResolver,
  type ResolvedGenkitLanguageModel,
} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";

// Exportiert für gezielte Tests der Vorgabe-Fallback-Kette.
export async function languageModelFor(
  languageModelId: string | undefined,
  teamId: string,
  resolver: GenkitLanguageModelResolver | undefined,
  defaultsStore: LanguageModelDefaultsStore | undefined,
): Promise<ResolvedGenkitLanguageModel | undefined> {
  const explicitId = languageModelId?.trim();
  if (explicitId) {
    if (!resolver) throw new Error("Die Sprachmodell-Auswahl ist nicht konfiguriert.");
    return resolver.resolve(teamId, explicitId);
  }
  return defaultLanguageModelFor(teamId, resolver, defaultsStore);
}

/**
 * "Standardmodell verwenden" (leere languageModelId): erst die in den Einstellungen gewählte
 * Vorgabe versuchen, sonst bleibt der umgebungsvariablen-gesteuerte Pfad (`ai-models.ts`) aktiv —
 * auch wenn die Vorgabe auf ein inzwischen gelöschtes Modell zeigt.
 */
async function defaultLanguageModelFor(
  teamId: string,
  resolver: GenkitLanguageModelResolver | undefined,
  defaultsStore: LanguageModelDefaultsStore | undefined,
): Promise<ResolvedGenkitLanguageModel | undefined> {
  if (!resolver || !defaultsStore) return undefined;
  const defaults = await defaultsStore.loadDefaults(teamId);
  if (!defaults.blockModelId) return undefined;
  try {
    return await resolver.resolve(teamId, defaults.blockModelId);
  } catch {
    return undefined;
  }
}
