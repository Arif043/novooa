import {type FastifyPluginAsyncTypebox, type Static, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {AssistantActor} from "../../features/assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../features/assistant/domain/entities/assistant-execution-context.js";
import {AssistantMessage} from "../../features/assistant/domain/entities/assistant-message.js";
import {AssistantRequest} from "../../features/assistant/domain/entities/assistant-request.js";
import {type KnowledgeBaseAssistant} from "../../features/knowledge_base/domain/usecases/knowledge-base-assistant.js";
import {type TaskBuilderAssistant} from "../../features/task_execution/domain/usecases/task-builder-assistant.js";
import {type ApplicationLogger, textSummary} from "../logging/application-logger.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";

export type AssistantRoutesOptions = {
  taskBuilderAssistant: (teamId: string) => Promise<TaskBuilderAssistant>;
  knowledgeBaseAssistant: (teamId: string) => Promise<KnowledgeBaseAssistant>;
  /** Protokoll des aktiven Arbeitsbereichs: Fehler gehen an die App und zusätzlich hierhin. */
  logger: ApplicationLogger;
};

const AssistantText = Type.String({minLength: 1, maxLength: 12000, pattern: "\\S"});
const AssistantQuestion = Type.Object({
  question: AssistantText,
  locale: Type.Optional(Type.Union([Type.Literal("en"), Type.Literal("de"), Type.Literal("tr")])),
  history: Type.Array(Type.Object({
    role: Type.Union([Type.Literal("user"), Type.Literal("agent")]), text: AssistantText,
  }), {maxItems: 8}),
});
const AssistantAnswer = Type.Object({
  answer: Type.String(), commands: Type.Array(Type.Unknown()), knowledgeCommands: Type.Array(Type.Unknown()),
});
const schema = {body: AssistantQuestion, response: {200: AssistantAnswer, 400: ErrorResponse}};

/**
 * Lokales Pendant zu `askTaskBuilderAssistant`/`askKnowledgeBaseAssistant`
 * (Firebase Callable Functions) — gleicher Anfrage-/Antwort-Vertrag, nur
 * über die reguläre Runtime-API. Kein Audit-Logging: Das dient dort der
 * teamübergreifenden Aufsicht, für einen einzelnen Standalone-Betreiber
 * ohne Mehrwert. Fehler landen aber im Protokoll des Arbeitsbereichs.
 *
 * Die Assistenten kommen als Factories und werden pro Anfrage gebaut.
 */
export const assistantRoutes: FastifyPluginAsyncTypebox<AssistantRoutesOptions> = async (app, options) => {
  app.post("/v1/assistant/task-builder", {schema}, async (request, reply) =>
    answer(() => options.taskBuilderAssistant(request.workspace.teamId), request.body, request.actor.uid)
      .catch((error: unknown) => failed(reply, options.logger, "assistant.task_builder_failed", error, request.body)));

  app.post("/v1/assistant/knowledge-base", {schema}, async (request, reply) =>
    answer(() => options.knowledgeBaseAssistant(request.workspace.teamId), request.body, request.actor.uid)
      .catch((error: unknown) => failed(reply, options.logger, "assistant.knowledge_base_failed", error, request.body)));
};

async function answer(
  assistantFor: () => Promise<TaskBuilderAssistant | KnowledgeBaseAssistant>,
  body: Static<typeof AssistantQuestion>,
  userId: string,
) {
  const history = body.history.map((message) => new AssistantMessage(message.role, message.text));
  const assistant = await assistantFor();
  return assistant.ask(
    new AssistantRequest(body.question, history, body.locale),
    new AssistantExecutionContext(new AssistantActor(userId)),
  );
}

/** Die Frage steht nur gekürzt im Protokoll; der Verlauf nur als Anzahl. */
function failed(
  reply: FastifyReply,
  logger: ApplicationLogger,
  event: string,
  error: unknown,
  body: Static<typeof AssistantQuestion>,
) {
  logger.exception(event, error, {...textSummary(body.question, "question"), historyMessages: body.history.length});
  return reply.code(400).send({error: messageFor(error)});
}

/** Fehler der Assistenten (z. B. kein Sprachmodell konfiguriert) sind für Nutzer:innen gedacht. */
function messageFor(error: unknown): string {
  return error instanceof Error ? error.message : "Die Assistentenanfrage konnte nicht verarbeitet werden.";
}
