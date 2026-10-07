import {type ScriptExecutionResult} from "../../domain/entities/script-execution.js";

/** Das Ergebnis eines Scripts aus der JSON-Antwort von Python; ohne `output` bleibt die Eingabe. */
export function scriptResultFrom(parsed: Record<string, unknown>, fallbackInput: string): ScriptExecutionResult {
  return {
    output: outputFrom(parsed, fallbackInput),
    variables: variablesFrom(parsed.variables),
    printed: typeof parsed.printed === "string" ? parsed.printed : "",
    errorOutput: typeof parsed.stderr === "string" ? parsed.stderr : "",
    workflowOutputs: Array.isArray(parsed.workflowOutputs) ? parsed.workflowOutputs as unknown[] : [],
  };
}

function outputFrom(parsed: Record<string, unknown>, fallback: string): string {
  if (parsed.outputDefined === false) return fallback;
  if (typeof parsed.output === "string") return parsed.output;
  throw new Error("Script hat keinen String-Output geliefert.");
}

function variablesFrom(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown> : {};
}
