import {z} from "genkit";
import {aiTurnMiddleware} from "../runner/node-attachment-genkit.js";
import {runEmployeeAgentTurn} from "../runner/employee-agent.js";
import {formatModelCallFinished, formatModelCallStarted} from "../runner/structured-logger.js";
import {promptContentFor, validStructuredFields} from "./prompt-node-input.js";
import {type PromptContent, type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";
import {type PromptModelCall} from "./prompt-model-call.js";
import {definedFieldsOf, fieldOutputsFor, structuredSchemaFor} from "./structured-output-schema.js";
import {withTranslatedGenkitErrors} from "../../../../language_models/infrastructure/errors/genkit-error-translator.js";
import {ModelOutputSchemaError} from "../../../../language_models/infrastructure/errors/language-model-errors.js";

export {fieldOutputsFor, structuredSchemaFor} from "./structured-output-schema.js";

type ModelResponse<T> = {output: T | undefined; text: string};

export async function executeTextPrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  const prompt = promptContentFor(input, call.workspace);
  const response = await logged(call, input, prompt, "Text", undefined,
    () => generate<z.ZodTypeAny>(call, input, prompt));
  return {answer: response.text, outputs: textOutputs(response.text)};
}

export async function executeDecisionPrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  if (input.choices.length === 0) throw new Error("Decision prompt requires at least one choice.");
  const prompt = promptContentFor(input, call.workspace);
  const schema = z.object({answer: z.enum(input.choices as [string, ...string[]])});
  const response = await logged(call, input, prompt, "Entscheidung", "answer: enum",
    () => generate(call, input, prompt, schema));
  const answer = response.output?.answer;
  if (answer === undefined) throw new ModelOutputSchemaError(`Die Entscheidung des Modells fehlt: ${response.text}`);
  return {answer, outputs: textOutputs(answer)};
}

export async function executeStructuredPrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  const fields = validStructuredFields(input.structuredFields);
  if (fields.length === 0) throw new Error("Strukturierte Ausgabe benötigt mindestens ein Feld.");
  const prompt = promptContentFor(input, call.workspace);
  const fieldNames = fields.map((field) => field.name).join(", ");
  const response = await logged(call, input, prompt, "Strukturierte Ausgabe", fieldNames,
    () => generate(call, input, prompt, structuredSchemaFor(fields)));
  const rawOutput: Record<string, unknown> | undefined = response.output;
  if (rawOutput === undefined) throw new ModelOutputSchemaError(`Das Modell lieferte keine strukturierte Ausgabe: ${response.text}`);
  const output = definedFieldsOf(rawOutput, fields);
  return {answer: JSON.stringify(output), outputs: fieldOutputsFor(output, fields)};
}

async function logged<T>(
  call: PromptModelCall, input: PromptNodeInput, prompt: PromptContent, kind: string,
  outputSchema: string | undefined, run: () => Promise<ModelResponse<T>>,
): Promise<ModelResponse<T>> {
  const label = input.employee ? `Prompt / ${kind} (Mitarbeiter: ${input.employee.name})` : `Prompt / ${kind}`;
  const startedAt = Date.now();
  call.logger.readableInfo(formatModelCallStarted({
    label, model: call.logContext, prompt: prompt.text, outputSchema,
    mediaCount: input.mediaUrls.length, options: call.config,
  }));
  const response = await run();
  call.logger.readableInfo(formatModelCallFinished({
    label, durationMs: Date.now() - startedAt, text: response.text, output: response.output,
  }));
  return response;
}

/** Mitarbeiter laufen als Agent; mit Bildern geht es direkt an das Modell, weil der Agent nur Text annimmt. */
async function generate<S extends z.ZodTypeAny>(
  call: PromptModelCall, input: PromptNodeInput, prompt: PromptContent, schema?: S,
): Promise<ModelResponse<z.infer<S>>> {
  const output = schema ? {schema} : undefined;
  const use = aiTurnMiddleware(call.workspace);
  return withTranslatedGenkitErrors(async () => {
    if (input.employee && input.mediaUrls.length === 0) {
      const response = await runEmployeeAgentTurn(call.ai, {
        employee: input.employee, model: call.model, prompt: prompt.text, use, output, config: call.config,
      });
      return {output: response.data ?? undefined, text: response.text};
    }
    const response = await call.ai.generate({model: call.model, prompt: prompt.content, output, use, config: call.config});
    return {output: response.output ?? undefined, text: response.text};
  });
}

function textOutputs(text: string) {
  return {value: {type: "string" as const, value: text}};
}
