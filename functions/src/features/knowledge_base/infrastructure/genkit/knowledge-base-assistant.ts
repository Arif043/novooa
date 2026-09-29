import {type AssistantResponder} from "../../../assistant/domain/repositories/assistant-responder.js";
import {AskAssistant} from "../../../assistant/domain/usecases/ask-assistant.js";
import {type KnowledgeBaseAssistantResponse} from "../../domain/entities/knowledge-base-assistant-response.js";
import {type KnowledgeBaseAssistant} from "../../domain/usecases/knowledge-base-assistant.js";

export function createKnowledgeBaseAssistant(
  responder: AssistantResponder<KnowledgeBaseAssistantResponse>,
): KnowledgeBaseAssistant {
  const askAssistant = new AskAssistant(responder);
  return {ask: (request, context) => askAssistant.execute(request, context)};
}
