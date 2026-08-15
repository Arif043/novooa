import {type AssistantExecutionContext} from "../entities/assistant-execution-context.js";
import {type AssistantRequest} from "../entities/assistant-request.js";
import {type AssistantResponder} from "../repositories/assistant-responder.js";

export class AskAssistant<TResponse> {
  constructor(private readonly responder: AssistantResponder<TResponse>) {}

  execute(
    request: AssistantRequest,
    context: AssistantExecutionContext,
  ): Promise<TResponse> {
    return this.responder.respond(request, context);
  }
}
