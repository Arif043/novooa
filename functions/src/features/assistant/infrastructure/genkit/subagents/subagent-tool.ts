import {z, type Genkit, type ModelArgument, type ToolAction, type ToolArgument} from "genkit";
import {type DelegationBudget} from "./delegation-budget.js";

export type SubagentSpec<I extends z.ZodTypeAny, O extends z.ZodTypeAny> = {
  name: string;
  description: string;
  model: ModelArgument;
  systemPrompt: string;
  tools: ToolArgument[];
  inputSchema: I;
  outputSchema: O;
  maxTurns: number;
  /** Optionale, deterministische Nachprüfung der Modellausgabe. */
  finalize?: (output: z.infer<O>) => z.infer<O>;
};

export type SubagentGenkit = Pick<Genkit, "dynamicTool" | "generate">;

/**
 * Macht einen spezialisierten Agenten zum Tool des Orchestrators
 * („Agents as Tools“). Fehler werden als Tool-Antwort statt als Exception
 * zurückgegeben, damit der Orchestrator sich selbst korrigieren kann.
 */
export function defineSubagentTool<I extends z.ZodTypeAny, O extends z.ZodTypeAny>(
  ai: SubagentGenkit,
  spec: SubagentSpec<I, O>,
  budget: DelegationBudget,
): ToolAction {
  return ai.dynamicTool(
    {
      name: spec.name,
      description: spec.description,
      inputSchema: spec.inputSchema,
      outputSchema: subagentResultSchema(spec.outputSchema),
    },
    async (input, options) => {
      if (!budget.tryConsume()) return failure("Das Delegationsbudget dieser Anfrage ist aufgebraucht.");
      return runSubagent(ai, spec, input, options.context);
    },
  ) as ToolAction;
}

export type SubagentResult<T> = {ok: boolean; ergebnis?: T; grund?: string};

export function subagentResultSchema<O extends z.ZodTypeAny>(
  outputSchema: O,
): z.ZodType<SubagentResult<z.infer<O>>> {
  return z.object({
    ok: z.boolean(),
    ergebnis: outputSchema.optional(),
    grund: z.string().optional(),
  }) as z.ZodType<SubagentResult<z.infer<O>>>;
}

async function runSubagent<I extends z.ZodTypeAny, O extends z.ZodTypeAny>(
  ai: SubagentGenkit,
  spec: SubagentSpec<I, O>,
  input: z.infer<I>,
  context: unknown,
): Promise<SubagentResult<z.infer<O>>> {
  try {
    const response = await ai.generate({
      model: spec.model,
      system: spec.systemPrompt,
      prompt: JSON.stringify(input),
      tools: spec.tools,
      context: context as Record<string, unknown> | undefined,
      maxTurns: spec.maxTurns,
      output: {schema: spec.outputSchema},
    });
    return resultFrom(spec, response.output);
  } catch (error) {
    return failure(`Der Subagent ${spec.name} ist fehlgeschlagen: ${messageOf(error)}`);
  }
}

function resultFrom<I extends z.ZodTypeAny, O extends z.ZodTypeAny>(
  spec: SubagentSpec<I, O>,
  output: unknown,
): SubagentResult<z.infer<O>> {
  const parsed = spec.outputSchema.safeParse(output);
  if (!parsed.success) return failure("Der Subagent hat keine gültige strukturierte Antwort geliefert.");
  const ergebnis = parsed.data as z.infer<O>;
  return {ok: true, ergebnis: spec.finalize ? spec.finalize(ergebnis) : ergebnis};
}

function failure(grund: string): SubagentResult<never> {
  return {ok: false, grund};
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
