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
import {FirestoreTeamContextStore} from "../../../teams/infrastructure/firebase/firestore-team-context-store.js";
import {FirestoreKnowledgeBaseAssistantNoteStore} from "../firebase/firestore-knowledge-base-assistant-note-store.js";
import {
  knowledgeBaseAssistantOutputSchema,
} from "../genkit/knowledge-base-assistant-output.js";
import {logKnowledgeBaseAssistantProposal} from "./knowledge-base-assistant-audit-event.js";
import {createKnowledgeBaseAssistantResponder} from "../genkit/knowledge-base-assistant-responder.js";
import {PublicPageHtmlFetcher} from "../genkit/public-page-html-fetcher.js";
import {PublicPageHttpClient} from "../genkit/public-page-http-client.js";

const ai = genkit({plugins: [googleAI()]});
const noteStore = new FirestoreKnowledgeBaseAssistantNoteStore();
const teamContextStore = new FirestoreTeamContextStore();
const pageFetcher = new PublicPageHtmlFetcher(new PublicPageHttpClient());
const responder = createKnowledgeBaseAssistantResponder({
  ai,
  model: googleAI.model(assistantGoogleModelName()),
  toolDependencies: {noteStore, teamContextStore, pageFetcher},
  modelConfig: assistantGoogleModelConfig(),
});
const askAssistant = new AskAssistant(responder);

export const knowledgeBaseAssistantFlow = ai.defineFlow(
  {
    name: "knowledgeBaseAssistantFlow",
    inputSchema: assistantCallableInputSchema,
    outputSchema: knowledgeBaseAssistantOutputSchema,
  },
  (input, runtime) => withExceptionLogging(
    "knowledge_base_assistant.failed",
    async () => executeKnowledgeBaseAssistant(input, runtime.context),
    {historyLength: input.history.length},
  ),
);

export const askKnowledgeBaseAssistant = onCallGenkit(
  {
    authPolicy: isSignedIn(),
    invoker: "public",
    secrets: [geminiApiKey],
  },
  knowledgeBaseAssistantFlow,
);

async function executeKnowledgeBaseAssistant(
  input: AssistantCallableInput,
  runtimeContext: Parameters<typeof assistantExecutionContextFrom>[0],
) {
  const context = assistantExecutionContextFrom(runtimeContext);
  const output = await askAssistant.execute(assistantRequestFromInput(input), context);
  logKnowledgeBaseAssistantProposal({
    uid: context.actor.id,
    historyLength: input.history.length,
    commands: output.knowledgeCommands,
  });
  return output;
}
