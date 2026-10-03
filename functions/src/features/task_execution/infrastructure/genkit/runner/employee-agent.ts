import {randomUUID} from "node:crypto";
import {defineAgent} from "@genkit-ai/ai";
import {Registry} from "@genkit-ai/core/registry";
import {type GenkitBeta} from "genkit/beta";
import type {
  AgentResponse,
  GenerateMiddleware,
  MiddlewareRef,
  ModelArgument,
  OutputOptions,
  z,
} from "genkit/beta";

import type {ResolvedEmployee} from "./task-definition.js";

/**
 * Führt einen Turn als Genkit-Agent aus: Die Rahmenbedingung des Mitarbeiters ist der System-Prompt, seine
 * Fähigkeiten reichen die Middleware in `use` (Skill- und Dateisystem-Middleware) durch. Ohne Mitarbeiter bleibt der
 * Executor bei `ai.generate(...)`.
 *
 * Der Agent wird in einer **Kind-Registry** angelegt, nicht in der der Runtime: `defineAgent` registriert fünf
 * Actions je Agent, die auf der langlebigen Registry nie wieder verschwänden. Das Kind löst Modelle und Plugins über
 * seine Eltern auf und wird mit dem Turn vom Speicher geräumt. Der Name bleibt mit einer UUID eindeutig. Es gibt
 * bewusst keinen Session-Store: pro Turn ein frischer Chat ohne gespeicherten Verlauf.
 */
export type EmployeeAgentTurnOptions<O extends z.ZodTypeAny = z.ZodTypeAny> = {
  employee: ResolvedEmployee;
  model: ModelArgument;
  /** Nutzer-Nachricht dieses Turns — die Anweisung des Bausteins, unverändert. */
  prompt: string;
  use?: (GenerateMiddleware | MiddlewareRef)[];
  output?: OutputOptions<O>;
  config?: Record<string, unknown>;
};

export async function runEmployeeAgentTurn<O extends z.ZodTypeAny = z.ZodTypeAny>(
  ai: GenkitBeta,
  options: EmployeeAgentTurnOptions<O>,
): Promise<AgentResponse<unknown, z.infer<O>>> {
  const {employee, model, use, output, config} = options;
  const constraint = employee.constraint.trim();
  const agent = defineAgent(Registry.withParent(ai.registry), {
    name: agentNameFor(employee),
    description: constraint.length > 0 ? constraint.split("\n")[0] : `Mitarbeiter ${employee.name}`,
    system: constraint.length > 0 ? constraint : undefined,
    model,
    use,
    output,
    config,
  });
  return agent.chat().send(options.prompt) as Promise<AgentResponse<unknown, z.infer<O>>>;
}

function agentNameFor(employee: ResolvedEmployee): string {
  const slug = employee.name.trim().toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 40);
  return `employee-${slug || "mitarbeiter"}-${randomUUID().slice(0, 8)}`;
}
