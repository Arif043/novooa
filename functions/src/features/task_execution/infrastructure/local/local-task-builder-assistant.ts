import {createTaskBuilderAssistantResponder} from "../genkit/assistant/task-builder-assistant-responder.js";
import {createTaskBuilderAssistant} from "../genkit/task-builder-assistant.js";
import {type TaskBuilderAssistant} from "../../domain/usecases/task-builder-assistant.js";
import {type GenkitLanguageModelResolver} from "../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../language_models/domain/repositories/language-model-defaults-store.js";
import {resolveAssistantLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-assistant-language-model.js";

/**
 * Wird pro Anfrage aufgerufen (siehe `assistantRoutes`), damit
 * eine in den Einstellungen geänderte Vorgabe sofort wirkt, statt einen
 * Neustart der Runtime zu brauchen — die Konstruktion selbst ist reine
 * Verdrahtung ohne I/O.
 */
export async function createLocalTaskBuilderAssistant(
  teamId: string,
  resolver: GenkitLanguageModelResolver,
  defaultsStore: LanguageModelDefaultsStore,
): Promise<TaskBuilderAssistant> {
  const {ai, model} = await resolveAssistantLanguageModel(teamId, resolver, defaultsStore);
  const responder = createTaskBuilderAssistantResponder({ai, model, modelConfig: {}});
  return createTaskBuilderAssistant(responder);
}
