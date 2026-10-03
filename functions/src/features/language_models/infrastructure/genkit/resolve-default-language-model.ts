import {type GenkitLanguageModelResolver, type ResolvedGenkitLanguageModel} from "./genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

export const noDefaultLanguageModelMessage =
  "Für den KI-Agenten fehlt ein Sprachmodell. Verbinde unter Einstellungen → Sprachmodelle ein Modell und wähle es als Standardmodell.";

/**
 * Das Sprachmodell des Nutzers für den lokalen KI-Agenten der Wissensbasis:
 * das Standardmodell, das er unter „Sprachmodelle“ gewählt hat. Es gibt keinen
 * Rückfall auf ein Modell des Betreibers — ohne gewähltes (oder mit gelöschtem)
 * Standardmodell bekommt der Nutzer einen Hinweis, was zu tun ist.
 */
export async function resolveDefaultLanguageModel(
  teamId: string,
  resolver: GenkitLanguageModelResolver,
  defaultsStore: LanguageModelDefaultsStore,
): Promise<ResolvedGenkitLanguageModel> {
  const {blockModelId} = await defaultsStore.loadDefaults(teamId);
  if (!blockModelId) throw new Error(noDefaultLanguageModelMessage);
  try {
    return await resolver.resolve(teamId, blockModelId);
  } catch {
    throw new Error(noDefaultLanguageModelMessage);
  }
}
