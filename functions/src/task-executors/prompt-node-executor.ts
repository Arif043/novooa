import {filesystem} from "@genkit-ai/middleware";
import { z, type Genkit } from "genkit";
import {modelLogContext, textModel} from "../task-runner/ai-models.js";
import {
  type NodeExecutor,
  executedNode,
} from "../task-runner/node-executor.js";
import {type WorkflowNode} from "../task-runner/task-definition.js";
import {
  formatModelCallFinished,
  formatModelCallStarted,
  logReadableInfo,
} from "../task-runner/structured-logger.js";
import {type NodeAttachmentWorkspace} from "../task-runner/node-attachment-workspace.js";

export type PromptNodeOutputType = "text" | "decision";

export type PromptNodeInput = {
  instruction: string;
  context: string;
  outputType: PromptNodeOutputType;
  choices: string[];
};

export type PromptNodeOutput = {
  answer: string;
};

export const promptNodeExecutor: NodeExecutor = {
  primitive: "prompt",
  async execute(input) {
    const output = await executePromptNode(
      input.ai,
      promptInputFor(input.node, input.context),
      input.attachmentWorkspace,
    );
    return executedNode(input.node, output.answer);
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
    use: attachmentMiddleware(attachmentWorkspace),
  });
  logReadableInfo(formatModelCallFinished({
    label: "Prompt / Text",
    durationMs: Date.now() - startedAt,
    text: response.text,
  }));
  return {answer: response.text};
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
  return {answer};
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
    use: attachmentMiddleware(attachmentWorkspace),
  });
  logReadableInfo(formatModelCallFinished({
    label: "Prompt / Entscheidung",
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
  if (attachmentWorkspace) {
    parts.push(attachmentInstructions(attachmentWorkspace));
  }
  if (input.outputType === "decision") {
    parts.push(`Antworte nur mit einer Option: ${input.choices.join(", ")}`);
  }
  return parts.join("\n\n");
}

function attachmentMiddleware(attachmentWorkspace?: NodeAttachmentWorkspace) {
  if (!attachmentWorkspace) return undefined;
  return [filesystem({rootDirectory: attachmentWorkspace.rootDirectory})];
}

function attachmentInstructions(workspace: NodeAttachmentWorkspace): string {
  const files = workspace.files
    .map((file) => `- ${file.filename} (${file.displayName})`)
    .join("\n");
  return [
    "Angehängte Dateien sind über die Dateisystem-Werkzeuge verfügbar.",
    "Nutze bei Bedarf list_files und read_file, um Inhalte zu prüfen.",
    `Verfügbare Dateien:\n${files}`,
  ].join("\n");
}

function promptInputFor(node: WorkflowNode, context: string): PromptNodeInput {
  const config = promptConfigFor(node);
  return {
    instruction: instructionFor(node),
    context,
    outputType: config?.outputType ?? "text",
    choices: choicesFor(node),
  };
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

function promptConfigFor(node: WorkflowNode) {
  if (node.config?.primitive !== "prompt") return undefined;
  return node.config;
}
