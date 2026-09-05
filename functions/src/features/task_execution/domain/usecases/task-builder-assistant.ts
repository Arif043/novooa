import {type AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {type AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {type TaskBuilderAssistantResponse} from "../entities/task-builder-assistant-response.js";

export interface TaskBuilderAssistant {
  ask(
    request: AssistantRequest,
    context: AssistantExecutionContext,
  ): Promise<TaskBuilderAssistantResponse>;
}
