import {type AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {type AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {type KnowledgeBaseAssistantResponse} from "../entities/knowledge-base-assistant-response.js";

export interface KnowledgeBaseAssistant {
  ask(
    request: AssistantRequest,
    context: AssistantExecutionContext,
  ): Promise<KnowledgeBaseAssistantResponse>;
}
