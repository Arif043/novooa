import {type NodeOutputValue} from "../entities/workflow-value.js";

/** Typen, die ein Script per `workflow_output(name, type, value)` liefern darf. */
export const scriptWorkflowOutputTypes = ["string", "number", "boolean", "datetime", "json"] as const;

type ScriptWorkflowOutputType = typeof scriptWorkflowOutputTypes[number];

/** Gleiche Regel wie `str.isidentifier()` im Script-Dienst: Buchstabe oder _, dann Buchstaben, Ziffern, _. */
const namePattern = /^[\p{L}_][\p{L}\p{N}_]*$/u;

export function isValidScriptWorkflowOutputName(name: unknown): name is string {
  return typeof name === "string" && namePattern.test(name) && name !== "value";
}

/** Eine Ausgabe ist ungültig; die Meldung ist für den Nutzer bestimmt. */
export class ScriptWorkflowOutputError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ScriptWorkflowOutputError";
  }
}

/**
 * Prüft die Ausgaben eines Scripts und macht daraus flache Workflow-Ausgabewerte.
 *
 * Der Script-Dienst prüft schon beim Aufruf (mit Zeilenangabe); diese Prüfung ist die
 * maßgebliche, weil die Runtime der Antwort des Dienstes nicht blind vertraut.
 */
export function workflowOutputsFrom(raw: readonly unknown[]): Record<string, NodeOutputValue> {
  const outputs: Record<string, NodeOutputValue> = {};
  for (const entry of raw) {
    const {name, type, value} = entryFrom(entry);
    if (name in outputs) throw new ScriptWorkflowOutputError(`workflow_output("${name}"): Der Name ist doppelt vergeben.`);
    outputs[name] = outputValue(name, type, value);
  }
  return outputs;
}

function entryFrom(entry: unknown): {name: string; type: ScriptWorkflowOutputType; value: unknown} {
  if (entry === null || typeof entry !== "object") throw new ScriptWorkflowOutputError("workflow_output: Ungültige Ausgabe.");
  const {name, type, value} = entry as Record<string, unknown>;
  if (!isValidScriptWorkflowOutputName(name)) {
    throw new ScriptWorkflowOutputError(`workflow_output: Der Name ${JSON.stringify(name)} ist ungültig.`);
  }
  if (!scriptWorkflowOutputTypes.includes(type as ScriptWorkflowOutputType)) {
    throw new ScriptWorkflowOutputError(`workflow_output("${name}"): Unbekannter Typ ${JSON.stringify(type)}.`);
  }
  return {name, type: type as ScriptWorkflowOutputType, value};
}

function outputValue(name: string, type: ScriptWorkflowOutputType, value: unknown): NodeOutputValue {
  const output = typedValue(type, value);
  if (output === null) throw new ScriptWorkflowOutputError(`workflow_output("${name}"): Der Wert ist kein ${type}.`);
  return output;
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
