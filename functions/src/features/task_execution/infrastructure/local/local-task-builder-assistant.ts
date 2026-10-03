import {createTaskBuilderAssistantResponder} from "../genkit/assistant/task-builder-assistant-responder.js";
import {createTaskBuilderAssistant} from "../genkit/task-builder-assistant.js";
import {type TaskBuilderAssistant} from "../../domain/usecases/task-builder-assistant.js";
import {type AssistantModelSettings} from "../../../language_models/domain/repositories/assistant-model-settings.js";
import {resolveAssistantLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-assistant-language-model.js";

/**
 * Das Modell legt die Cloud fest; die Runtime erfährt es per Firestore-
 * Listener (`modelSettings`, siehe `RuntimeAssistantModel`). Ohne Wert gilt
 * das Standardmodell (siehe `resolveAssistantLanguageModel`).
 */
export async function createLocalTaskBuilderAssistant(
  modelSettings: AssistantModelSettings,
): Promise<TaskBuilderAssistant> {
  const {ai, model} = await resolveAssistantLanguageModel(modelSettings);
  const responder = createTaskBuilderAssistantResponder({ai, model, modelConfig: {}});
  return createTaskBuilderAssistant(responder);
}
