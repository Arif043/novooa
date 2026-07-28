import { z } from "genkit";
import { type GenkitBeta } from "genkit/beta";
import {modelLogContext, textModel} from "../runner/ai-models.js";
import {
  type NodeExecutor,
  type TaskRunContext,
  executedNode,
  stringOutput,
  textOutputs,
} from "../runner/node-executor.js";
import {
  type EmployeeAttachment,
  type NodeOutputValue,
  type WorkflowNode,
} from "../runner/task-definition.js";
import {
  formatModelCallFinished,
  formatModelCallStarted,
  logReadableInfo,
} from "../runner/structured-logger.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {
  attachmentInstructions,
  aiTurnMiddleware,
} from "../runner/node-attachment-genkit.js";
import {
  employeeFor,
  renderEmployeePrompt,
} from "../runner/employee-context.js";
import {runEmployeeAgentTurn} from "../runner/employee-agent.js";
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
  employee?: EmployeeAttachment;
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
  ai: GenkitBeta,
  input: PromptNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  if (input.outputType === "decision") {
    return executeDecisionPrompt(ai, input, attachmentWorkspace);
  }
  if (input.outputType === "structured") {
    return executeStructuredPrompt(ai, input, attachmentWorkspace);
  }
  return executeTextPrompt(ai, input, attachmentWorkspace);
}

async function executeTextPrompt(
  ai: GenkitBeta,
  input: PromptNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  const prompt = promptTurn(input, attachmentWorkspace);
  const startedAt = Date.now();
  const label = input.employee
    ? `Prompt / Text (Mitarbeiter: ${input.employee.name})`
    : "Prompt / Text";
  logReadableInfo(formatModelCallStarted({
    label,
    model: modelLogContext(),
    prompt,
  }));

  const text = input.employee
    ? (await runEmployeeAgentTurn(ai, {
      employee: input.employee,
      model: textModel(),
      prompt,
      use: aiTurnMiddleware(attachmentWorkspace),
    })).text
    : (await ai.generate({
      model: textModel(),
      prompt,
      use: aiTurnMiddleware(attachmentWorkspace),
    })).text;

  logReadableInfo(formatModelCallFinished({
    label,
    durationMs: Date.now() - startedAt,
    text,
  }));
  return {answer: text, outputs: textOutputs(text)};
}

async function executeDecisionPrompt(
  ai: GenkitBeta,
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
  const label = input.employee
    ? `Prompt / Entscheidung (Mitarbeiter: ${input.employee.name})`
    : "Prompt / Entscheidung";
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label,
    model: modelLogContext(),
    prompt,
    outputSchema: "answer: enum",
  }));

  let answer: string | undefined;
  let logText = "";
  let logOutput: unknown;
  if (input.employee) {
    const response = await runEmployeeAgentTurn(ai, {
      employee: input.employee,
      model: textModel(),
      prompt,
      use: aiTurnMiddleware(attachmentWorkspace),
      output: {schema},
    });
    answer = response.data?.answer;
    logText = response.text;
    logOutput = response.data;
  } else {
    const response = await ai.generate({
      model: textModel(),
      prompt,
      output: {schema},
      use: aiTurnMiddleware(attachmentWorkspace),
    });
    answer = response.output?.answer;
    logText = response.text;
    logOutput = response.output;
  }
  logReadableInfo(formatModelCallFinished({
    label,
    durationMs: Date.now() - startedAt,
    text: logText,
    output: logOutput,
  }));
  if (answer === undefined) {
    throw new Error(`Decision prompt returned no structured answer: ${logText}`);
  }
  return {answer, outputs: textOutputs(answer)};
}

async function executeStructuredPrompt(
  ai: GenkitBeta,
  input: PromptNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  const fields = validStructuredFields(input.structuredFields);
  if (fields.length === 0) {
    throw new Error("Strukturierte Ausgabe benötigt mindestens ein Feld.");
  }
  const prompt = promptTurn(input, attachmentWorkspace);
  const schema = structuredSchemaFor(fields);
  const label = input.employee
    ? `Prompt / Strukturierte Ausgabe (Mitarbeiter: ${input.employee.name})`
    : "Prompt / Strukturierte Ausgabe";
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label,
    model: modelLogContext(),
    prompt,
    outputSchema: fields.map((field) => field.name).join(", "),
  }));

  let output: Record<string, string> | undefined | null;
  let logText = "";
  if (input.employee) {
    const response = await runEmployeeAgentTurn(ai, {
      employee: input.employee,
      model: textModel(),
      prompt,
      use: aiTurnMiddleware(attachmentWorkspace),
      output: {schema},
    });
    output = response.data ?? undefined;
    logText = response.text;
  } else {
    const response = await ai.generate({
      model: textModel(),
      prompt,
      output: {schema},
      use: aiTurnMiddleware(attachmentWorkspace),
    });
    output = response.output ?? undefined;
    logText = response.text;
  }
  logReadableInfo(formatModelCallFinished({
    label,
    durationMs: Date.now() - startedAt,
    text: logText,
    output,
  }));
  if (output === undefined || output === null) {
    throw new Error(`Prompt lieferte keine strukturierte Ausgabe: ${logText}`);
  }
  const answer = JSON.stringify(output);
  return {answer, outputs: {...textOutputs(answer), ...outputsFor(output)}};
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
  const employee = employeeFor(node);
  const rawInstruction = instructionFor(node);
  const rendered = employee
    ? renderEmployeePrompt(employee.promptTemplate, rawInstruction)
    : rawInstruction;
  return {
    instruction: resolveTemplates(rendered),
    context: resolveTemplates(context),
    outputType: config?.outputType ?? "text",
    choices: choicesFor(node).map(resolveTemplates),
    structuredFields: structuredFieldsFor(node),
    employee,
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
