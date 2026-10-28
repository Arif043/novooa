import {type LlmOutputSpec, type LlmResponse} from "../../../../language_models/domain/prompting/llm-gateway.js";
import {ModelOutputSchemaError} from "../../../../language_models/infrastructure/errors/language-model-errors.js";
import {validStructuredFields} from "./prompt-node-input.js";
import {promptNodePrompt} from "./prompt-node-prompt.js";
import {type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";
import {bindingFor, type PromptModelCall} from "./prompt-model-call.js";
import {definedFieldsOf, fieldOutputsFor} from "./structured-output-schema.js";

export {fieldOutputsFor, structuredSchemaFor} from "./structured-output-schema.js";


export async function executeTextPrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  const response = await generate(call, input, "Text", {kind: "text"});
  return {answer: response.text, outputs: textOutputs(response.text)};
}

export async function executeDecisionPrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  if (input.choices.length === 0) throw new Error("Decision prompt requires at least one choice.");
  const response = await generate(call, input, "Entscheidung", {kind: "choice", choices: input.choices});
  const answer = response.data;
  if (typeof answer !== "string") throw new ModelOutputSchemaError(`Die Entscheidung des Modells fehlt: ${response.text}`);
  return {answer, outputs: textOutputs(answer)};
}

export async function executeStructuredPrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  const fields = validStructuredFields(input.structuredFields);
  if (fields.length === 0) throw new Error("Strukturierte Ausgabe benötigt mindestens ein Feld.");
  const response = await generate(call, input, "Strukturierte Ausgabe", {kind: "structured", fields});
  if (!isRecord(response.data)) throw new ModelOutputSchemaError(`Das Modell lieferte keine strukturierte Ausgabe: ${response.text}`);
  const output = definedFieldsOf(response.data, fields);
  return {answer: JSON.stringify(output), outputs: fieldOutputsFor(output, fields)};
}

/** Ein Aufruf über das LLM-Framework; mit Mitarbeiter steht seine Rahmenbedingung im Systemteil. */
function generate(call: PromptModelCall, input: PromptNodeInput, kind: string, output: LlmOutputSpec): Promise<LlmResponse> {
  return call.gateway.generate({
    binding: bindingFor(call), prompt: promptNodePrompt(input, call.workspace), label: promptNodeLabel(input, kind), output,
  });
}

/** Bezeichnung im Protokoll, mit Mitarbeiter, falls einer den Baustein ausführt. */
export function promptNodeLabel(input: PromptNodeInput, kind: string): string {
  return input.employee ? `Prompt / ${kind} (Mitarbeiter: ${input.employee.name})` : `Prompt / ${kind}`;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function textOutputs(text: string) {
  return {value: {type: "string" as const, value: text}};
}
