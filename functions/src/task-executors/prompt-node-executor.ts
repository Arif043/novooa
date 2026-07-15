import { z, type Genkit } from "genkit";
import {modelLogContext, textModel} from "../task-runner/ai-models.js";
import {
  type NodeExecutor,
  type TaskRunContext,
  executedNode,
  stringOutput,
  textOutputs,
} from "../task-runner/node-executor.js";
import {
  type NodeOutputValue,
  type WorkflowNode,
} from "../task-runner/task-definition.js";
import {
  formatModelCallFinished,
  formatModelCallStarted,
  logReadableInfo,
} from "../task-runner/structured-logger.js";
import {type NodeAttachmentWorkspace} from "../task-runner/node-attachment-workspace.js";
import {
  attachmentInstructions,
  aiTurnMiddleware,
} from "../task-runner/node-attachment-genkit.js";
export type PromptNodeOutputType = "text" | "decision" | "structured";

type StructuredOutputField = {
  name: string;
  description: string;
};

export type PromptNodeInput = {
  instruction: string;
  context: string;
  outputType: PromptNodeOutputType;
  choices: string[];
  structuredFields: StructuredOutputField[];
};

export type PromptNodeOutput = {
  answer: string;
  outputs: Record<string, NodeOutputValue>;
};

export const promptNodeExecutor: NodeExecutor = {
  primitive: "prompt",
  async execute(input, runContext) {
    const output = await executePromptNode(
      input.ai,
      promptInputFor(input.node, input.context, runContext.resolveTemplates),
      input.attachmentWorkspace,
    );
    return executedNode(input.node, output.outputs);
  },
};

export async function executePromptNode(
  ai: Genkit,
  input: PromptNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  if (input.outputType === "decision") {
    return executeDecisionPrompt(ai, input, attachmentWorkspace);
  }
  if (input.outputType === "structured") {
    return executeStructuredPrompt(ai, input, attachmentWorkspace);
  }

  const prompt = promptTurn(input, attachmentWorkspace);
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: "Prompt / Text",
    model: modelLogContext(),
    prompt,
  }));
  const response = await ai.generate({
    model: textModel(),
    prompt,
    use: aiTurnMiddleware(attachmentWorkspace),
  });
  logReadableInfo(formatModelCallFinished({
    label: "Prompt / Text",
    durationMs: Date.now() - startedAt,
    text: response.text,
  }));
  return {answer: response.text, outputs: textOutputs(response.text)};
}

async function executeDecisionPrompt(
  ai: Genkit,
  input: PromptNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  if (input.choices.length === 0) {
    throw new Error("Decision prompt requires at least one choice.");
  }
  const prompt = promptTurn(input, attachmentWorkspace);
  const schema = z.object({
    answer: z.enum(input.choices as [string, ...string[]]),
  });
  const decision = await generateDecision(ai, prompt, schema, attachmentWorkspace);
  const answer = decision.output?.answer;
  if (answer === undefined) {
    throw new Error(`Decision prompt returned no structured answer: ${decision.text}`);
  }
  return {answer, outputs: textOutputs(answer)};
}

async function executeStructuredPrompt(
  ai: Genkit,
  input: PromptNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  const fields = validStructuredFields(input.structuredFields);
  if (fields.length === 0) {
    throw new Error("Strukturierte Ausgabe benötigt mindestens ein Feld.");
  }
  const prompt = promptTurn(input, attachmentWorkspace);
  const schema = structuredSchemaFor(fields);
  const response = await generateStructured(ai, prompt, schema, fields, attachmentWorkspace);
  if (response.output === undefined || response.output === null) {
    throw new Error(`Prompt lieferte keine strukturierte Ausgabe: ${response.text}`);
  }
  const answer = JSON.stringify(response.output);
  return {answer, outputs: {...textOutputs(answer), ...outputsFor(response.output)}};
}

async function generateDecision(
  ai: Genkit,
  prompt: string,
  schema: z.ZodObject<{answer: z.ZodEnum<[string, ...string[]]>}>,
  attachmentWorkspace?: NodeAttachmentWorkspace,
) {
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: "Prompt / Entscheidung",
    model: modelLogContext(),
    prompt,
    outputSchema: "answer: enum",
  }));
  const response = await ai.generate({
    model: textModel(),
    prompt,
    output: {schema},
    use: aiTurnMiddleware(attachmentWorkspace),
  });
  logReadableInfo(formatModelCallFinished({
    label: "Prompt / Entscheidung",
    durationMs: Date.now() - startedAt,
    text: response.text,
    output: response.output,
  }));
  return response;
}

async function generateStructured(
  ai: Genkit,
  prompt: string,
  schema: z.ZodObject<Record<string, z.ZodString>>,
  fields: StructuredOutputField[],
  attachmentWorkspace?: NodeAttachmentWorkspace,
) {
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: "Prompt / Strukturierte Ausgabe",
    model: modelLogContext(),
    prompt,
    outputSchema: fields.map((field) => field.name).join(", "),
  }));
  const response = await ai.generate({
    model: textModel(),
    prompt,
    output: {schema},
    use: aiTurnMiddleware(attachmentWorkspace),
  });
  logReadableInfo(formatModelCallFinished({
    label: "Prompt / Strukturierte Ausgabe",
    durationMs: Date.now() - startedAt,
    text: response.text,
    output: response.output,
  }));
  return response;
}

function promptTurn(
  input: PromptNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
): string {
  const parts = [input.instruction];
  if (input.context.trim().length > 0) parts.push(`Kontext:\n${input.context}`);
  const instructions = attachmentInstructions(attachmentWorkspace);
  if (instructions) parts.push(instructions);
  if (input.outputType === "decision") {
    parts.push(`Antworte nur mit einer Option: ${input.choices.join(", ")}`);
  }
  if (input.outputType === "structured") {
    parts.push("Fülle alle Felder der strukturierten Ausgabe aus.");
  }
  return parts.join("\n\n");
}

function promptInputFor(
  node: WorkflowNode,
  context: string,
  resolveTemplates: TaskRunContext["resolveTemplates"],
): PromptNodeInput {
  const config = promptConfigFor(node);
  return {
    instruction: resolveTemplates(instructionFor(node)),
    context: resolveTemplates(context),
    outputType: config?.outputType ?? "text",
    choices: choicesFor(node).map(resolveTemplates),
    structuredFields: structuredFieldsFor(node),
  };
}

function validStructuredFields(fields: StructuredOutputField[]) {
  return fields.filter((field) => field.name.trim().length > 0);
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

function outputsFor(output: Record<string, string>) {
  return Object.entries(output).reduce<Record<string, NodeOutputValue>>(
    (outputs, [key, value]) => {
      outputs[key] = stringOutput(value);
      return outputs;
    },
    {},
  );
}

function instructionFor(node: WorkflowNode): string {
  const instruction = promptConfigFor(node)?.instruction.trim();
  if (instruction && instruction.length > 0) return instruction;
  if (node.description.trim().length > 0) return node.description;
  return node.title;
}

function choicesFor(node: WorkflowNode): string[] {
  const config = promptConfigFor(node);
  const choices = config?.choices.length ? config.choices : [
    config?.firstChoice ?? "",
    config?.secondChoice ?? "",
  ];
  return choices.filter((choice) => choice.trim().length > 0);
}

function structuredFieldsFor(node: WorkflowNode): StructuredOutputField[] {
  const config = promptConfigFor(node);
  return config?.structuredFields ?? [];
}

function promptConfigFor(node: WorkflowNode) {
  if (node.config?.primitive !== "prompt") return undefined;
  return node.config;
}
