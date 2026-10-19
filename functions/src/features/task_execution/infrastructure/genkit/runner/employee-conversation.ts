import {randomUUID} from "node:crypto";
import {defineAgent} from "@genkit-ai/ai";
import {Registry} from "@genkit-ai/core/registry";
import {type GenkitBeta} from "genkit/beta";
import type {AgentChat, GenerateOptions, ModelArgument} from "genkit/beta";

import type {ResolvedEmployee} from "./task-definition.js";

export type EmployeeConversationOptions = {
  ai: GenkitBeta;
  employee: ResolvedEmployee;
  model: ModelArgument;
  use?: GenerateOptions["use"];
  config?: Record<string, unknown>;
};

/**
 * Ein Gespräch mit einem Mitarbeiter über mehrere Aufträge eines Laufs: Folgeaufträge sehen die früheren
 * Aufträge und Antworten. Läuft als Genkit-Agent (`defineAgent`) in einer Kind-Registry seiner Genkit-Instanz,
 * damit die fünf Actions des Agenten mit dem Lauf verschwinden.
 *
 * Bewusst ohne Ausgabeschema: Der Agent kopiert seinen Zustand per `structuredClone`, und mit Schema enthält
 * er eine Parser-Funktion („could not be cloned“, Genkit 1.42). Aufträge laufen nacheinander, weil ein Chat
 * keinen zweiten Turn gleichzeitig annimmt, der Orchestrator aber parallel delegieren darf.
 */
export class EmployeeConversation {
  private chat?: AgentChat;
  private queue: Promise<unknown> = Promise.resolve();

  constructor(private readonly options: EmployeeConversationOptions) {}

  send(prompt: string): Promise<string> {
    const turn = this.queue.then(() => this.turn(prompt));
    this.queue = turn.catch(() => undefined);
    return turn;
  }

  private async turn(prompt: string): Promise<string> {
    const response = await this.chatOf().send(prompt);
    return response.text;
  }

  private chatOf(): AgentChat {
    if (this.chat) return this.chat;
    const {ai, employee, model, use, config} = this.options;
    const constraint = employee.constraint.trim();
    const agent = defineAgent(Registry.withParent(ai.registry), {
      name: `employee-${randomUUID().slice(0, 8)}`,
      description: `Mitarbeiter ${employee.name}`,
      system: constraint.length > 0 ? constraint : undefined,
      model,
      use,
      config,
    });
    this.chat = agent.chat();
    return this.chat;
  }
}
