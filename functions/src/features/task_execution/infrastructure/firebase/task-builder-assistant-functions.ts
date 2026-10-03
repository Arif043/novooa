import {HttpsError, isSignedIn, onCall} from "firebase-functions/v2/https";
import {AssistantMessage} from "../../../assistant/domain/entities/assistant-message.js";
import {AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {geminiApiKey} from "../../../../shared/genkit/gemini-secret.js";
import {withExceptionLogging} from "../../../../shared/logging/logger.js";
import {runTaskBuilderAssistant} from "./run-task-builder-assistant.js";


export const askTaskBuilderAssistant = onCall(
  {
    authPolicy: isSignedIn(),
    invoker: "public",
    secrets: [geminiApiKey],
  },
  async (request) => withExceptionLogging(
    "task_builder_assistant.failed",
    async () => ask(request.data, request.auth),
    {historyLength: historyLengthFrom(request.data)},
  ),
);

async function ask(data: unknown, auth: {uid: string} | undefined) {
  const input = inputFrom(data);
  return runTaskBuilderAssistant({request: input.request, actorId: actorFrom(auth).uid});
}

function inputFrom(data: unknown): {
  request: AssistantRequest;
  historyLength: number;
} {
  const input = recordFrom(data, "Die Assistentenanfrage erwartet ein Objekt.");
  const question = boundedString(input.question, "question");
  if (question.trim().length === 0) {
    throw invalidInput("question darf nicht leer sein.");
  }
  const history = historyFrom(input.history);
  return {
    request: new AssistantRequest(question, history),
    historyLength: history.length,
  };
}

function historyFrom(value: unknown): AssistantMessage[] {
  if (!Array.isArray(value) || value.length > 8) {
    throw invalidInput("history muss ein Array mit maximal acht Einträgen sein.");
  }
  return value.map((item) => {
    const message = recordFrom(item, "Ein history-Eintrag muss ein Objekt sein.");
    const role = message.role;
    if (role !== "user" && role !== "agent") {
      throw invalidInput("role muss user oder agent sein.");
    }
    return new AssistantMessage(role, boundedString(message.text, "history.text"));
  });
}

function actorFrom(auth: {uid: string} | undefined): {uid: string} {
  if (!auth?.uid) throw new HttpsError("unauthenticated", "Anmeldung ist erforderlich.");
  return {uid: auth.uid};
}

function historyLengthFrom(data: unknown): number {
  if (data === null || typeof data !== "object" || Array.isArray(data)) return 0;
  const history = (data as Record<string, unknown>).history;
  return Array.isArray(history) ? history.length : 0;
}

function recordFrom(value: unknown, message: string): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw invalidInput(message);
}

function boundedString(value: unknown, name: string): string {
  if (typeof value === "string" && value.length <= 12000) return value;
  throw invalidInput(`${name} muss ein String mit maximal 12000 Zeichen sein.`);
}

function invalidInput(message: string): HttpsError {
  return new HttpsError("invalid-argument", message);
}
