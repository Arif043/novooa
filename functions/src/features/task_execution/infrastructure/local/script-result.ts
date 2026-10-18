import {type ScriptExecutionResult} from "../../domain/entities/script-execution.js";

/** Das Ergebnis eines Scripts aus der JSON-Antwort von Python. */
export function scriptResultFrom(parsed: Record<string, unknown>): ScriptExecutionResult {
  return {
    printed: typeof parsed.printed === "string" ? parsed.printed : "",
    errorOutput: typeof parsed.stderr === "string" ? parsed.stderr : "",
    workflowOutputs: Array.isArray(parsed.workflowOutputs) ? parsed.workflowOutputs as unknown[] : [],
  };
}
