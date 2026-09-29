import {AskAssistant} from "../../../assistant/domain/usecases/ask-assistant.js";
import {type AssistantResponder} from "../../../assistant/domain/repositories/assistant-responder.js";
import {type TaskBuilderAssistantResponse} from "../../domain/entities/task-builder-assistant-response.js";
import {type TaskBuilderAssistant} from "../../domain/usecases/task-builder-assistant.js";

export function createTaskBuilderAssistant(
  responder: AssistantResponder<TaskBuilderAssistantResponse>,
): TaskBuilderAssistant {
  const askAssistant = new AskAssistant(responder);
  return {ask: (request, context) => askAssistant.execute(request, context)};
}
