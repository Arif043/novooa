import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "./local-runtime-http-server.js";
import {routeMatch} from "./local-runtime-route.js";
import {AssistantActor} from "../../features/assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../features/assistant/domain/entities/assistant-execution-context.js";
import {AssistantMessage, type AssistantRole} from "../../features/assistant/domain/entities/assistant-message.js";
import {AssistantRequest} from "../../features/assistant/domain/entities/assistant-request.js";
import {type TaskBuilderAssistant} from "../../features/task_execution/domain/usecases/task-builder-assistant.js";
import {type KnowledgeBaseAssistant} from "../../features/knowledge_base/domain/usecases/knowledge-base-assistant.js";

const maximumQuestionLength = 12000;
const maximumHistoryLength = 8;

/**
 * Lokales Pendant zu `askTaskBuilderAssistant`/`askKnowledgeBaseAssistant`
 * (Firebase Callable Functions) — gleicher Anfrage-/Antwort-Vertrag, nur
 * über die reguläre Runtime-API statt eine Cloud Function. Kein
 * Audit-Logging: Das dient dort der teamübergreifenden Aufsicht, für einen
 * einzelnen Standalone-Betreiber ohne Mehrwert.
 *
 * Die Assistenten kommen als Factories statt fertiger Instanzen: Sie lösen
 * das konfigurierte Sprachmodell bei jedem Aufruf neu auf (siehe
 * `createLocalTaskBuilderAssistant`), damit eine in den Einstellungen
 * geänderte Vorgabe ohne Neustart der Runtime wirkt.
 */
export class LocalAssistantHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly taskBuilderAssistant: () => Promise<TaskBuilderAssistant>,
    private readonly knowledgeBaseAssistant: () => Promise<KnowledgeBaseAssistant>,
    private readonly userId: string,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (routeMatch(request, "POST", "/v1/assistant/task-builder")) {
      return this.ask(this.taskBuilderAssistant, request.body);
    }
    if (routeMatch(request, "POST", "/v1/assistant/knowledge-base")) {
      return this.ask(this.knowledgeBaseAssistant, request.body);
    }
    return null;
  }

  private async ask(
    assistantFor: () => Promise<TaskBuilderAssistant | KnowledgeBaseAssistant>,
    body: unknown,
  ): Promise<LocalRuntimeResponse> {
    try {
      const request = assistantRequestFrom(body);
      const context = new AssistantExecutionContext(new AssistantActor(this.userId));
      const assistant = await assistantFor();
      const output = await assistant.ask(request, context);
      return {body: output, statusCode: 200};
    } catch (error) {
      return {body: {error: messageFor(error)}, statusCode: 400};
    }
  }
}

function assistantRequestFrom(body: unknown): AssistantRequest {
  const input = recordFrom(body);
  const question = boundedString(input.question, "question");
  return new AssistantRequest(question, historyFrom(input.history));
}

function historyFrom(value: unknown): AssistantMessage[] {
  if (!Array.isArray(value) || value.length > maximumHistoryLength) {
    throw new Error(`history muss ein Array mit maximal ${maximumHistoryLength} Einträgen sein.`);
  }
  return value.map(messageFrom);
}

function messageFrom(value: unknown): AssistantMessage {
  const input = recordFrom(value);
  const role = input.role;
  if (role !== "user" && role !== "agent") {
    throw new Error("role muss user oder agent sein.");
  }
  return new AssistantMessage(role as AssistantRole, boundedString(input.text, "history.text"));
}

function recordFrom(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new Error("Die Assistentenanfrage erwartet ein Objekt.");
}

function boundedString(value: unknown, name: string): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= maximumQuestionLength) {
    return value;
  }
  throw new Error(`${name} muss ein nicht leerer String mit maximal ${maximumQuestionLength} Zeichen sein.`);
}

function messageFor(error: unknown): string {
  return error instanceof Error ? error.message : "Die Assistentenanfrage konnte nicht verarbeitet werden.";
}
