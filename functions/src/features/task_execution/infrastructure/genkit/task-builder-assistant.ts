import {googleAI} from "@genkit-ai/google-genai";
import {genkit} from "genkit";
import {AskAssistant} from "../../../assistant/domain/usecases/ask-assistant.js";
import {type AssistantResponder} from "../../../assistant/domain/repositories/assistant-responder.js";
import {type TaskBuilderAssistantResponse} from "../../domain/entities/task-builder-assistant-response.js";
import {type TaskBuilderAssistant} from "../../domain/usecases/task-builder-assistant.js";
import {
  assistantGoogleModelConfig,
  assistantGoogleModelName,
} from "../../../assistant/infrastructure/genkit/assistant-google-config.js";
import {createTaskBuilderAssistantResponder} from "./assistant/task-builder-assistant-responder.js";

export function createGenkitTaskBuilderAssistant(): TaskBuilderAssistant {
  const ai = genkit({plugins: [googleAI()]});
  const responder = createTaskBuilderAssistantResponder({
    ai,
    model: googleAI.model(assistantGoogleModelName()),
    modelConfig: assistantGoogleModelConfig(),
  });
  return createTaskBuilderAssistant(responder);
}

export function createTaskBuilderAssistant(
  responder: AssistantResponder<TaskBuilderAssistantResponse>,
): TaskBuilderAssistant {
  const askAssistant = new AskAssistant(responder);
  return {ask: (request, context) => askAssistant.execute(request, context)};
}
