import {
  type NodeExecutorInput,
  type ParentNodeOutput,
  type TaskRunContext,
} from "../runner/node-executor.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {attachmentInstructions} from "../runner/node-attachment-genkit.js";
import {employeeFor, renderEmployeePrompt} from "../runner/employee-context.js";
import {mediaDataUrlFor} from "../runner/media-value-loader.js";
import {type NodeOutputValue, type WorkflowNode} from "../runner/task-definition.js";
import {type PromptContent, type PromptNodeInput, type StructuredOutputField} from "./prompt-node-types.js";

export async function promptInputFor(
  input: NodeExecutorInput,
  runContext: TaskRunContext,
): Promise<PromptNodeInput> {
  const config = promptConfigFor(input.node);
  const employee = employeeFor(input.node);
  return {
    instruction: instructionFor(input.node, employee, runContext),
    context: contextFor(input.parentOutputs, input.context),
    outputType: config.outputType,
    choices: config.choices.map(runContext.resolveTemplates),
    structuredFields: config.structuredFields,
    mediaUrls: await mediaUrlsFor(input.parentOutputs, runContext),
    employee,
  };
}

export function promptContentFor(
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
): PromptContent {
  const text = promptTextFor(input, workspace);
  if (input.mediaUrls.length === 0) return {text, content: text};
  return {text, content: [{text}, ...input.mediaUrls.map(mediaPartFor)]};
}

function instructionFor(
  node: WorkflowNode,
  employee: PromptNodeInput["employee"],
  runContext: TaskRunContext,
): string {
  const instruction = rawInstructionFor(node);
  const rendered = employee
    ? renderEmployeePrompt(employee.promptTemplate, instruction)
    : instruction;
  return runContext.resolveTemplates(rendered);
}

function rawInstructionFor(node: WorkflowNode): string {
  const instruction = node.config.primitive === "prompt"
    ? node.config.instruction.trim()
    : "";
  if (instruction.length > 0) return instruction;
  return node.description.trim() || node.title;
}

function promptConfigFor(node: WorkflowNode) {
  if (node.config.primitive !== "prompt") {
    throw new Error("Prompt-Konfiguration fehlt.");
  }
  return node.config;
}

function contextFor(outputs: ParentNodeOutput[], context: string): string {
  const values = outputs
    .filter((output) => output.value.type !== "media")
    .map((output) => valueTextFor(output.value))
    .filter((value) => value.length > 0);
  return [context, ...values].filter((value) => value.length > 0).join("\n\n");
}

async function mediaUrlsFor(
  outputs: ParentNodeOutput[],
  runContext: TaskRunContext,
): Promise<string[]> {
  return Promise.all(outputs.flatMap((output) => {
    if (output.value.type !== "media") return [];
    return [mediaDataUrlFor(
      output.value.value,
      runContext.teamId,
      runContext.fileContentReader,
    )];
  }));
}

function valueTextFor(value: NodeOutputValue): string {
  if (value.type === "string" || value.type === "datetime") return value.value;
  if (value.type === "number" || value.type === "boolean") return String(value.value);
  if (value.type === "json") return JSON.stringify(value.value);
  return `Datei: ${value.value.displayName}`;
}

function promptTextFor(
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
): string {
  const parts = [input.instruction];
  if (input.context.trim().length > 0) parts.push(`Kontext:\n${input.context}`);
  const instructions = attachmentInstructions(workspace);
  if (instructions) parts.push(instructions);
  if (input.outputType === "decision") {
    parts.push(`Antworte nur mit einer Option: ${input.choices.join(", ")}`);
  }
  if (input.outputType === "structured") {
    parts.push("Fülle alle Felder der strukturierten Ausgabe aus.");
  }
  return parts.join("\n\n");
}

function mediaPartFor(url: string): {media: {url: string}} {
  return {media: {url}};
}

export function validStructuredFields(
  fields: StructuredOutputField[],
): StructuredOutputField[] {
  return fields.filter((field) => field.name.trim().length > 0);
}
