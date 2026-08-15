import {googleAI} from "@genkit-ai/google-genai";
import {genkit, type ActionContext, z} from "genkit";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {AssistantActor} from "../../../assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {AssistantMessage} from "../../../assistant/domain/entities/assistant-message.js";
import {AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {AskAssistant} from "../../../assistant/domain/usecases/ask-assistant.js";
import {withExceptionLogging} from "../../../../shared/logging/logger.js";
import {geminiApiKey} from "../../../task_execution/infrastructure/genkit/runner/gemini-secret.js";
import {FirestoreTeamContextStore} from "../../../teams/infrastructure/firebase/firestore-team-context-store.js";
import {FirestoreKnowledgeBaseAssistantNoteStore} from "../firebase/firestore-knowledge-base-assistant-note-store.js";
import {
  knowledgeBaseAssistantOutputSchema,
} from "../genkit/knowledge-base-assistant-output.js";
import {logKnowledgeBaseAssistantProposal} from "./knowledge-base-assistant-audit-event.js";
import {KnowledgeBaseAssistantGenkitResponder} from "../genkit/knowledge-base-assistant-responder.js";
import {PublicPageHtmlFetcher} from "../genkit/public-page-html-fetcher.js";
import {PublicPageHttpClient} from "../genkit/public-page-http-client.js";

const ai = genkit({plugins: [googleAI()]});
const noteStore = new FirestoreKnowledgeBaseAssistantNoteStore();
const teamContextStore = new FirestoreTeamContextStore();
const pageFetcher = new PublicPageHtmlFetcher(new PublicPageHttpClient());
const responder = new KnowledgeBaseAssistantGenkitResponder({
  ai,
  model: googleAI.model(knowledgeBaseModel()),
  toolDependencies: {noteStore, teamContextStore, pageFetcher},
  modelConfig: assistantConfig(),
});
const askAssistant = new AskAssistant(responder);

const assistantMessageSchema = z.object({
  role: z.enum(["user", "agent"]),
  text: z.string().max(12000),
});

const knowledgeBaseAssistantInputSchema = z.object({
  question: z.string().min(1).max(12000),
  history: z.array(assistantMessageSchema).max(8),
});

export const knowledgeBaseAssistantFlow = ai.defineFlow(
  {
    name: "knowledgeBaseAssistantFlow",
    inputSchema: knowledgeBaseAssistantInputSchema,
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

function executionContextFrom(
  context: ActionContext | undefined,
): AssistantExecutionContext {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return new AssistantExecutionContext(new AssistantActor(auth.uid));
}

async function executeKnowledgeBaseAssistant(
  input: z.infer<typeof knowledgeBaseAssistantInputSchema>,
  runtimeContext: ActionContext | undefined,
) {
  const context = executionContextFrom(runtimeContext);
  const output = await askAssistant.execute(requestFromInput(input), context);
  logKnowledgeBaseAssistantProposal({
    uid: context.actor.id,
    historyLength: input.history.length,
    commands: output.knowledgeCommands,
  });
  return output;
}

function requestFromInput(
  input: z.infer<typeof knowledgeBaseAssistantInputSchema>,
): AssistantRequest {
  return new AssistantRequest(
    input.question,
    input.history.map(({role, text}) => new AssistantMessage(role, text)),
  );
}

function knowledgeBaseModel(): string {
  return process.env.GOOGLE_TEXT_MODEL?.trim() || "gemini-3.1-flash-lite";
}

function assistantConfig() {
  return {
    temperature: 0.2,
    tools: [{urlContext: {}}],
    toolConfig: {includeServerSideToolInvocations: true},
  };
}
