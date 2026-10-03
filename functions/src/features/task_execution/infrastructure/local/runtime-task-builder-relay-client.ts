import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type TaskBuilderAssistantResponse} from "../../domain/entities/task-builder-assistant-response.js";

export type TaskBuilderRelayInput = {
  question: string;
  history: {role: "user" | "agent"; text: string}[];
};

export interface RuntimeTaskBuilderRelayClient {
  ask(license: SignedRuntimeLicense, input: TaskBuilderRelayInput): Promise<TaskBuilderAssistantResponse>;
}

export class HttpRuntimeTaskBuilderRelayClient implements RuntimeTaskBuilderRelayClient {
  private readonly endpoint: URL;

  constructor(endpoint: string) {
    this.endpoint = new URL(endpoint);
    if (this.endpoint.protocol !== "https:") throw new Error("Der Assistenten-Relay muss HTTPS verwenden.");
  }

  async ask(license: SignedRuntimeLicense, input: TaskBuilderRelayInput): Promise<TaskBuilderAssistantResponse> {
    const response = await fetch(this.endpoint, {
      method: "POST", headers: {"content-type": "application/json"},
      body: JSON.stringify({license, ...input}),
      // Das Modell kann dauern; die Cloud-Funktion bricht selbst nach 120 s ab.
      signal: AbortSignal.timeout(125_000),
    });
    if (!response.ok) throw new Error("Der KI-Agent in der Cloud hat die Anfrage abgelehnt.");
    return responseFrom(await response.json());
  }
}

/** Ohne konfigurierte Relay-URL meldet der Client „nicht verfügbar“, statt zu scheitern. */
export class UnavailableRuntimeTaskBuilderRelayClient implements RuntimeTaskBuilderRelayClient {
  async ask(): Promise<TaskBuilderAssistantResponse> {
    throw new Error("Der KI-Agent der Cloud ist in dieser Runtime nicht konfiguriert.");
  }
}

function responseFrom(value: unknown): TaskBuilderAssistantResponse {
  const body = value as Partial<TaskBuilderAssistantResponse> | null;
  if (typeof body?.answer !== "string" || !Array.isArray(body.commands) || !Array.isArray(body.knowledgeCommands)) {
    throw new Error("Der KI-Agent in der Cloud hat eine ungültige Antwort geliefert.");
  }
  return {answer: body.answer, commands: body.commands, knowledgeCommands: body.knowledgeCommands};
}
