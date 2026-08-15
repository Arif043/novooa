import {type AssistantExecutionContext} from "../entities/assistant-execution-context.js";
import {type AssistantRequest} from "../entities/assistant-request.js";

export interface AssistantResponder<TResponse> {
  respond(
    request: AssistantRequest,
    context: AssistantExecutionContext,
  ): Promise<TResponse>;
}
