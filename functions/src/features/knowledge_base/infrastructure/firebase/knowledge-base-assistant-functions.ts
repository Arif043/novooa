import {HttpsError, isSignedIn, onCall} from "firebase-functions/v2/https";
import {type AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {
  assistantCallableInputSchema,
  assistantRequestFromInput,
} from "../../../assistant/infrastructure/firebase/assistant-callable-input.js";
import {
  assistantExecutionContextFrom,
} from "../../../assistant/infrastructure/firebase/assistant-callable-runtime-context.js";
import {geminiApiKey} from "../../../../shared/genkit/gemini-secret.js";
import {withExceptionLogging} from "../../../../shared/logging/logger.js";
import {FirestoreTeamContextStore} from "../../../teams/infrastructure/firebase/firestore-team-context-store.js";
import {type KnowledgeBaseAssistant} from "../../domain/usecases/knowledge-base-assistant.js";
import {createGenkitKnowledgeBaseAssistant} from "../genkit/knowledge-base-assistant.js";
import {PublicPageHtmlFetcher} from "../genkit/public-page-html-fetcher.js";
import {PublicPageHttpClient} from "../genkit/public-page-http-client.js";
import {FirestoreKnowledgeBaseAssistantNoteStore} from "./firestore-knowledge-base-assistant-note-store.js";
import {logKnowledgeBaseAssistantProposal} from "./knowledge-base-assistant-audit-event.js";

const knowledgeBaseAssistant = createGenkitKnowledgeBaseAssistant({
  noteStore: new FirestoreKnowledgeBaseAssistantNoteStore(),
  teamContextStore: new FirestoreTeamContextStore(),
  pageFetcher: new PublicPageHtmlFetcher(new PublicPageHttpClient()),
});

export const askKnowledgeBaseAssistant = onCall(
  {
    authPolicy: isSignedIn(),
    invoker: "public",
    secrets: [geminiApiKey],
  },
  async (request) => withExceptionLogging(
    "knowledge_base_assistant.failed",
    async () => ask(knowledgeBaseAssistant, request.data, request.auth),
    {historyLength: historyLengthFrom(request.data)},
  ),
);

async function ask(
  assistant: KnowledgeBaseAssistant,
  data: unknown,
  auth: {uid: string} | undefined,
) {
  const input = inputFrom(data);
  const context = assistantExecutionContextFrom({auth});
  const output = await assistant.ask(input.request, context);
  logKnowledgeBaseAssistantProposal({
    uid: context.actor.id,
    historyLength: input.historyLength,
    commands: output.knowledgeCommands,
  });
  return output;
}

function inputFrom(data: unknown): {
  request: AssistantRequest;
  historyLength: number;
} {
  const parsed = assistantCallableInputSchema.safeParse(data);
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Die Assistentenanfrage ist ungültig.",
    );
  }
  return {
    request: assistantRequestFromInput(parsed.data),
    historyLength: parsed.data.history.length,
  };
}

function historyLengthFrom(data: unknown): number {
  if (data === null || typeof data !== "object" || Array.isArray(data)) return 0;
  const history = (data as Record<string, unknown>).history;
  return Array.isArray(history) ? history.length : 0;
}
