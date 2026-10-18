import {err, ok, type Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
import {type NodeOutputValue} from "../entities/workflow-value.js";

/** Typen, die ein Script per `workflow_output(name, type, value)` liefern darf. */
export const scriptWorkflowOutputTypes = ["string", "number", "boolean", "datetime", "json"] as const;

type ScriptWorkflowOutputType = typeof scriptWorkflowOutputTypes[number];

/** Gleiche Regel wie `str.isidentifier()` im Script-Dienst: Buchstabe oder _, dann Buchstaben, Ziffern, _. */
const namePattern = /^[\p{L}_][\p{L}\p{N}_]*$/u;

export function isValidScriptWorkflowOutputName(name: unknown): name is string {
  return typeof name === "string" && namePattern.test(name) && name !== "value";
}

/**
 * Prüft die Ausgaben eines Scripts und macht daraus flache Workflow-Ausgabewerte.
 *
 * Der Script-Dienst prüft schon beim Aufruf (mit Zeilenangabe); diese Prüfung ist die
 * maßgebliche, weil die Runtime der Antwort des Dienstes nicht blind vertraut.
 */
export function workflowOutputsFrom(raw: readonly unknown[]): Result<Record<string, NodeOutputValue>, NodeFailure> {
  const outputs: Record<string, NodeOutputValue> = {};
  for (const entry of raw) {
    const outputOrFailure = entryFrom(entry).andThen(({name, type, value}) => name in outputs
      ? err(nodeFailures.scriptOutputInvalid("duplicateName", name))
      : outputValue(name, type, value).map((output) => ({name, output})));
    if (outputOrFailure.isErr()) return err(outputOrFailure.error);
    outputs[outputOrFailure.value.name] = outputOrFailure.value.output;
  }
  return ok(outputs);
}

type ScriptWorkflowOutputEntry = {name: string; type: ScriptWorkflowOutputType; value: unknown};

function entryFrom(entry: unknown): Result<ScriptWorkflowOutputEntry, NodeFailure> {
  if (entry === null || typeof entry !== "object") return err(nodeFailures.scriptOutputInvalid("invalidEntry"));
  const {name, type, value} = entry as Record<string, unknown>;
  if (!isValidScriptWorkflowOutputName(name)) {
    return err(nodeFailures.scriptOutputInvalid("invalidName", JSON.stringify(name) ?? "undefined"));
  }
  if (!scriptWorkflowOutputTypes.includes(type as ScriptWorkflowOutputType)) {
    return err(nodeFailures.scriptOutputInvalid("unknownType", name, JSON.stringify(type) ?? "undefined"));
  }
  return ok({name, type: type as ScriptWorkflowOutputType, value});
}

function outputValue(name: string, type: ScriptWorkflowOutputType, value: unknown): Result<NodeOutputValue, NodeFailure> {
  const output = typedValue(type, value);
  return output === null ? err(nodeFailures.scriptOutputInvalid("wrongValueType", name, type)) : ok(output);
}

function typedValue(type: ScriptWorkflowOutputType, value: unknown): NodeOutputValue | null {
  switch (type) {
  case "string": return typeof value === "string" ? {type, value} : null;
  case "number": return typeof value === "number" && Number.isFinite(value) ? {type, value} : null;
  case "boolean": return typeof value === "boolean" ? {type, value} : null;
  case "datetime": return typeof value === "string" && !Number.isNaN(Date.parse(value)) ? {type, value} : null;
  case "json": return value === undefined ? null : {type, value};
  }
}
