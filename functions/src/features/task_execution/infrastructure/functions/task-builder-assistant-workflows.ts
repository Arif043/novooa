import {googleAI} from "@genkit-ai/google-genai";
import {genkit} from "genkit";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {AskAssistant} from "../../../assistant/domain/usecases/ask-assistant.js";
import {
  assistantCallableInputSchema,
  type AssistantCallableInput,
  assistantRequestFromInput,
} from "../../../assistant/infrastructure/functions/assistant-callable-input.js";
import {
  assistantExecutionContextFrom,
} from "../../../assistant/infrastructure/functions/assistant-callable-runtime-context.js";
import {
  assistantGoogleModelConfig,
  assistantGoogleModelName,
} from "../../../assistant/infrastructure/genkit/assistant-google-config.js";
import {withExceptionLogging} from "../../../../shared/logging/logger.js";
import {geminiApiKey} from "../../../../shared/genkit/gemini-secret.js";
import {taskBuilderAssistantOutputSchema} from "../genkit/assistant/task-builder-assistant-output.js";
import {createTaskBuilderAssistantResponder} from "../genkit/assistant/task-builder-assistant-responder.js";
import {logTaskBuilderAssistantProposal} from "./task-builder-assistant-audit-event.js";

const ai = genkit({plugins: [googleAI()]});
const responder = createTaskBuilderAssistantResponder({
  ai,
  model: googleAI.model(assistantGoogleModelName()),
  modelConfig: assistantGoogleModelConfig(),
});
const askAssistant = new AskAssistant(responder);

export const taskBuilderAssistantFlow = ai.defineFlow(
  {
    name: "taskBuilderAssistantFlow",
    inputSchema: assistantCallableInputSchema,
    outputSchema: taskBuilderAssistantOutputSchema,
  },
  (input, runtime) => withExceptionLogging(
    "task_builder_assistant.failed",
    async () => executeTaskBuilderAssistant(input, runtime.context),
    {historyLength: input.history.length},
  ),
);

export const askTaskBuilderAssistant = onCallGenkit(
  {
    authPolicy: isSignedIn(),
    invoker: "public",
    secrets: [geminiApiKey],
  },
  taskBuilderAssistantFlow,
);

async function executeTaskBuilderAssistant(
  input: AssistantCallableInput,
  runtimeContext: Parameters<typeof assistantExecutionContextFrom>[0],
) {
  const context = assistantExecutionContextFrom(runtimeContext);
  const output = await askAssistant.execute(assistantRequestFromInput(input), context);
  logTaskBuilderAssistantProposal({
    uid: context.actor.id,
    historyLength: input.history.length,
    commands: output.commands,
  });
  return output;
}
