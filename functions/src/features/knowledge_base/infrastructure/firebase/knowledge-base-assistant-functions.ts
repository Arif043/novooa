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
import {createKnowledgeBaseAssistant} from "../genkit/knowledge-base-assistant.js";
import {createKnowledgeBaseAssistantResponder} from "../genkit/knowledge-base-assistant-responder.js";
import {PublicPageHtmlFetcher} from "../genkit/public-page-html-fetcher.js";
import {PublicPageHttpClient} from "../genkit/public-page-http-client.js";
import {FirestoreKnowledgeBaseAssistantNoteStore} from "./firestore-knowledge-base-assistant-note-store.js";
import {logKnowledgeBaseAssistantProposal} from "./knowledge-base-assistant-audit-event.js";
import {RemoteConfigAssistantModel} from "../../../language_models/infrastructure/firebase/remote-config-assistant-model.js";
import {resolveAssistantLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-assistant-language-model.js";

const teamContextStore = new FirestoreTeamContextStore();
const noteStore = new FirestoreKnowledgeBaseAssistantNoteStore();
const pageFetcher = new PublicPageHtmlFetcher(new PublicPageHttpClient());

const assistantModel = new RemoteConfigAssistantModel();

export const askKnowledgeBaseAssistant = onCall(
  {
    authPolicy: isSignedIn(),
    invoker: "public",
    // Modell, Tools und Notizinhalte brauchen mehr als die 256 MiB der Vorgabe.
    memory: "512MiB",
    secrets: [geminiApiKey],
  },
  async (request) => withExceptionLogging(
    "knowledge_base_assistant.failed",
    async () => ask(request.data, request.auth),
    {historyLength: historyLengthFrom(request.data)},
  ),
);

async function ask(data: unknown, auth: {uid: string} | undefined) {
  const input = inputFrom(data);
  const context = assistantExecutionContextFrom({auth});
  const {ai, model} = await resolveAssistantLanguageModel(assistantModel);
  const assistant = createKnowledgeBaseAssistant(
    createKnowledgeBaseAssistantResponder({
      ai,
      model,
      modelConfig: {},
      toolDependencies: {noteStore, teamContextStore, pageFetcher},
    }),
  );
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
