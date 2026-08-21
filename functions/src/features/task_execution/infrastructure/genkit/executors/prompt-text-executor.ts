import {z} from "genkit";
import {type GenkitBeta} from "genkit/beta";
import {modelLogContext, textModel} from "../runner/ai-models.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {aiTurnMiddleware} from "../runner/node-attachment-genkit.js";
import {runEmployeeAgentTurn} from "../runner/employee-agent.js";
import {formatModelCallFinished, formatModelCallStarted, logReadableInfo} from "../runner/structured-logger.js";
import {promptContentFor, validStructuredFields} from "./prompt-node-input.js";
import {type PromptNodeInput, type PromptNodeOutput, type StructuredOutputField} from "./prompt-node-types.js";

export async function executeTextPrompt(
  ai: GenkitBeta,
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  const prompt = promptContentFor(input, workspace);
  const label = input.employee ? `Prompt / Text (Mitarbeiter: ${input.employee.name})` : "Prompt / Text";
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({label, model: modelLogContext(), prompt: prompt.text}));
  const text = await textResponseFor(ai, input, prompt, workspace);
  logReadableInfo(formatModelCallFinished({
    label, durationMs: Date.now() - startedAt, text,
  }));
  return {answer: text, outputs: textOutputs(text)};
}

export async function executeDecisionPrompt(
  ai: GenkitBeta,
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  if (input.choices.length === 0) throw new Error("Decision prompt requires at least one choice.");
  const prompt = promptContentFor(input, workspace);
  const schema = z.object({answer: z.enum(input.choices as [string, ...string[]])});
  const label = input.employee ? `Prompt / Entscheidung (Mitarbeiter: ${input.employee.name})` : "Prompt / Entscheidung";
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label, model: modelLogContext(), prompt: prompt.text, outputSchema: "answer: enum",
  }));
  const response = await decisionResponseFor(ai, input, prompt, schema, workspace);
  logReadableInfo(formatModelCallFinished({
    label, durationMs: Date.now() - startedAt, text: response.text, output: response.answer,
  }));
  if (response.answer === undefined) {
    throw new Error(`Decision prompt returned no structured answer: ${response.text}`);
  }
  return {answer: response.answer, outputs: textOutputs(response.answer)};
}

export async function executeStructuredPrompt(
  ai: GenkitBeta,
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  const fields = validStructuredFields(input.structuredFields);
  if (fields.length === 0) throw new Error("Strukturierte Ausgabe benötigt mindestens ein Feld.");
  const prompt = promptContentFor(input, workspace);
  const schema = structuredSchemaFor(fields);
  const label = input.employee ? `Prompt / Strukturierte Ausgabe (Mitarbeiter: ${input.employee.name})` : "Prompt / Strukturierte Ausgabe";
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label, model: modelLogContext(), prompt: prompt.text,
    outputSchema: fields.map((field) => field.name).join(", "),
  }));
  const response = await structuredResponseFor(ai, input, prompt, schema, workspace);
  logReadableInfo(formatModelCallFinished({
    label, durationMs: Date.now() - startedAt, text: response.text, output: response.output,
  }));
  if (response.output === undefined) {
    throw new Error(`Prompt lieferte keine strukturierte Ausgabe: ${response.text}`);
  }
  const answer = JSON.stringify(response.output);
  return {answer, outputs: {
    value: {type: "json", value: response.output},
    text: {type: "string", value: answer},
    ...fieldOutputsFor(response.output),
  }};
}

async function textResponseFor(
  ai: GenkitBeta, input: PromptNodeInput, prompt: ReturnType<typeof promptContentFor>, workspace?: NodeAttachmentWorkspace,
): Promise<string> {
  if (input.employee && input.mediaUrls.length === 0) {
    return (await runEmployeeAgentTurn(ai, {
      employee: input.employee, model: textModel(), prompt: prompt.text, use: aiTurnMiddleware(workspace),
    })).text;
  }
  return (await ai.generate({
    model: textModel(), prompt: prompt.content, use: aiTurnMiddleware(workspace),
  })).text;
}

async function decisionResponseFor(
  ai: GenkitBeta, input: PromptNodeInput, prompt: ReturnType<typeof promptContentFor>, schema: z.ZodType<{answer: string}>, workspace?: NodeAttachmentWorkspace,
): Promise<{answer: string | undefined; text: string}> {
  if (input.employee && input.mediaUrls.length === 0) {
    const response = await runEmployeeAgentTurn(ai, {
      employee: input.employee, model: textModel(), prompt: prompt.text,
      use: aiTurnMiddleware(workspace), output: {schema},
    });
    return {answer: response.data?.answer, text: response.text};
  }
  const response = await ai.generate({
    model: textModel(), prompt: prompt.content, output: {schema}, use: aiTurnMiddleware(workspace),
  });
  return {answer: response.output?.answer, text: response.text};
}

async function structuredResponseFor(
  ai: GenkitBeta, input: PromptNodeInput, prompt: ReturnType<typeof promptContentFor>, schema: z.ZodType<Record<string, string>>, workspace?: NodeAttachmentWorkspace,
): Promise<{output: Record<string, string> | undefined; text: string}> {
  if (input.employee && input.mediaUrls.length === 0) {
    const response = await runEmployeeAgentTurn(ai, {
      employee: input.employee, model: textModel(), prompt: prompt.text,
      use: aiTurnMiddleware(workspace), output: {schema},
    });
    return {output: response.data ?? undefined, text: response.text};
  }
  const response = await ai.generate({
    model: textModel(), prompt: prompt.content, output: {schema}, use: aiTurnMiddleware(workspace),
  });
  return {output: response.output ?? undefined, text: response.text};
}

function structuredSchemaFor(fields: StructuredOutputField[]) {
  const shape = fields.reduce<Record<string, z.ZodString>>((schema, field) => {
    schema[field.name.trim()] = field.description.trim().length === 0
      ? z.string().min(1)
      : z.string().min(1).describe(field.description.trim());
    return schema;
  }, {});
  return z.object(shape);
}

function fieldOutputsFor(output: Record<string, string>) {
  return Object.entries(output).reduce<Record<string, {type: "string"; value: string}>>(
    (outputs, [key, value]) => ({...outputs, [key]: {type: "string", value}}),
    {},
  );
}

function textOutputs(text: string) {
  const value = {type: "string" as const, value: text};
  return {value, text: value};
}
