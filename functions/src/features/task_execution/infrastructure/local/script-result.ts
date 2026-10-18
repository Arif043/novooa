import {type ScriptExecutionResult} from "../../domain/entities/script-execution.js";

/** Das Ergebnis eines Scripts aus der JSON-Antwort von Python. */
export function scriptResultFrom(parsed: Record<string, unknown>): ScriptExecutionResult {
  return {
    variables: variablesFrom(parsed.variables),
    printed: typeof parsed.printed === "string" ? parsed.printed : "",
    errorOutput: typeof parsed.stderr === "string" ? parsed.stderr : "",
    workflowOutputs: Array.isArray(parsed.workflowOutputs) ? parsed.workflowOutputs as unknown[] : [],
  };
}

function variablesFrom(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown> : {};
}
