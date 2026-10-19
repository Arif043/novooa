import {type GenkitBeta} from "genkit/beta";
import type {
  GenerateOptions,
  ModelArgument,
  OutputOptions,
  Part,
  z,
} from "genkit/beta";

import type {ResolvedEmployee} from "./task-definition.js";

/**
 * Führt einen Turn eines Mitarbeiters aus: Seine Rahmenbedingung ist der System-Prompt, seine Fähigkeiten reichen
 * die Middleware in `use` (Skill- und Dateisystem-Middleware) durch. Pro Turn gibt es keinen gespeicherten Verlauf.
 *
 * Bewusst `generate` statt Genkits `defineAgent`: Der Agent legt die Modellantwort samt Parser-Funktion in seinen
 * Session-Zustand und kopiert ihn per `structuredClone`; mit Ausgabeschema scheitert das immer („could not be
 * cloned“, Genkit 1.42). Für einen einzelnen Turn ohne Verlauf bringt der Agent nichts darüber hinaus.
 */
export type EmployeeAgentTurnOptions<O extends z.ZodTypeAny = z.ZodTypeAny> = {
  employee: ResolvedEmployee;
  model: ModelArgument;
  /** Nutzer-Nachricht dieses Turns — die Anweisung des Bausteins, unverändert, ggf. mit Bildern. */
  prompt: string | Part[];
  use?: GenerateOptions["use"];
  output?: OutputOptions<O>;
  config?: Record<string, unknown>;
};

export type EmployeeAgentTurnResponse<T> = {text: string; data: T | null};

export async function runEmployeeAgentTurn<O extends z.ZodTypeAny = z.ZodTypeAny>(
  ai: GenkitBeta,
  options: EmployeeAgentTurnOptions<O>,
): Promise<EmployeeAgentTurnResponse<z.infer<O>>> {
  const {employee, model, prompt, use, output, config} = options;
  const constraint = employee.constraint.trim();
  const response = await ai.generate({
    model,
    system: constraint.length > 0 ? constraint : undefined,
    prompt,
    use,
    output,
    config,
  });
  return {text: response.text, data: response.output ?? null};
}
