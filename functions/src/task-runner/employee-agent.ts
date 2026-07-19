import {randomUUID} from "node:crypto";
import {type GenkitBeta} from "genkit/beta";
import type {
  Agent,
  AgentResponse,
  GenerateMiddleware,
  MiddlewareRef,
  ModelArgument,
  OutputOptions,
  z,
} from "genkit/beta";

import type {EmployeeAttachment} from "./task-definition.js";

/**
 * Definiert einen Genkit-Agent aus einem Mitarbeiter und führt einen
 * einzelnen Turn aus. Wenn der User einem Baustein einen Mitarbeiter
 * zuweist, wird dieser Weg gewählt — sonst nutzt der Executor weiterhin
 * `ai.generate(...)`.
 *
 * Der Agent-Name wird pro Aufruf mit einer UUID eindeutig gemacht, damit
 * Registry-Kollisionen in derselben Function-Instanz ausgeschlossen sind.
 * Wir verwenden die Beta-API bewusst ohne Session-Store: pro Node-Turn
 * ein frischer Chat, kein persistiertes History.
 */
export type EmployeeAgentTurnOptions<O extends z.ZodTypeAny = z.ZodTypeAny> = {
  employee: EmployeeAttachment;
  model: ModelArgument;
  /** User-Prompt für diesen Turn — bereits mit `{{instruction}}` gerendert. */
  prompt: string;
  use?: (GenerateMiddleware | MiddlewareRef)[];
  output?: OutputOptions<O>;
  config?: Record<string, unknown>;
};

export async function runEmployeeAgentTurn<O extends z.ZodTypeAny = z.ZodTypeAny>(
  ai: GenkitBeta,
  options: EmployeeAgentTurnOptions<O>,
): Promise<AgentResponse<unknown, z.infer<O>>> {
  const agent = defineEmployeeAgent(ai, options);
  const chat = agent.chat();
  return chat.send(options.prompt) as Promise<
    AgentResponse<unknown, z.infer<O>>
  >;
}

function defineEmployeeAgent<O extends z.ZodTypeAny = z.ZodTypeAny>(
  ai: GenkitBeta,
  options: EmployeeAgentTurnOptions<O>,
): Agent<unknown> {
  const {employee, model, use, output, config} = options;
  return ai.defineAgent({
    name: agentNameFor(employee),
    description: employee.role.trim().length > 0
      ? employee.role.trim().split("\n")[0]
      : `Mitarbeiter ${employee.name || employee.employeeId}`,
    system: employee.role.trim().length > 0 ? employee.role : undefined,
    model,
    use,
    output,
    config,
  });
}

function agentNameFor(employee: EmployeeAttachment): string {
  const slug = slugify(employee.name || employee.employeeId) || "employee";
  return `employee-${slug}-${randomUUID().slice(0, 8)}`;
}

function slugify(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40);
}
