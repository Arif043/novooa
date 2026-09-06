import {googleAI} from "@genkit-ai/google-genai";
import {genkit} from "genkit";
import {type AssistantResponder} from "../../../assistant/domain/repositories/assistant-responder.js";
import {AskAssistant} from "../../../assistant/domain/usecases/ask-assistant.js";
import {
  assistantGoogleModelConfig,
  assistantGoogleModelName,
} from "../../../assistant/infrastructure/genkit/assistant-google-config.js";
import {type KnowledgeBaseAssistantResponse} from "../../domain/entities/knowledge-base-assistant-response.js";
import {type KnowledgeBaseAssistant} from "../../domain/usecases/knowledge-base-assistant.js";
import {createKnowledgeBaseAssistantResponder} from "./knowledge-base-assistant-responder.js";
import {type KnowledgeBaseAssistantToolDependencies} from "./knowledge-base-assistant-tools.js";

export function createGenkitKnowledgeBaseAssistant(
  toolDependencies: KnowledgeBaseAssistantToolDependencies,
): KnowledgeBaseAssistant {
  const ai = genkit({plugins: [googleAI()]});
  const responder = createKnowledgeBaseAssistantResponder({
    ai,
    model: googleAI.model(assistantGoogleModelName()),
    toolDependencies,
    modelConfig: assistantGoogleModelConfig(),
  });
  return createKnowledgeBaseAssistant(responder);
}

export function createKnowledgeBaseAssistant(
  responder: AssistantResponder<KnowledgeBaseAssistantResponse>,
): KnowledgeBaseAssistant {
  const askAssistant = new AskAssistant(responder);
  return {ask: (request, context) => askAssistant.execute(request, context)};
}
