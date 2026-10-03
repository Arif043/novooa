import {type GenkitLanguageModelResolver, type ResolvedGenkitLanguageModel} from "./genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

export const noDefaultLanguageModelMessage =
  "Für den KI-Agenten fehlt ein Sprachmodell. Verbinde unter Einstellungen → Sprachmodelle ein Modell und wähle es als Sprachmodell des Wissensbasis-Agenten oder als Standardmodell.";

/**
 * Das Sprachmodell des Nutzers für den lokalen KI-Agenten der Wissensbasis:
 * das Modell, das er dafür unter „Sprachmodelle“ gewählt hat, sonst sein
 * Standardmodell. Es gibt keinen Rückfall auf ein Modell des Betreibers — ohne
 * gewähltes (oder mit gelöschtem) Modell bekommt der Nutzer einen Hinweis, was
 * zu tun ist.
 */
export async function resolveDefaultLanguageModel(
  teamId: string,
  resolver: GenkitLanguageModelResolver,
  defaultsStore: LanguageModelDefaultsStore,
): Promise<ResolvedGenkitLanguageModel> {
  const defaults = await defaultsStore.loadDefaults(teamId);
  const modelId = defaults.knowledgeAssistantModelId ?? defaults.blockModelId;
  if (!modelId) throw new Error(noDefaultLanguageModelMessage);
  try {
    return await resolver.resolve(teamId, modelId);
  } catch {
    throw new Error(noDefaultLanguageModelMessage);
  }
}
