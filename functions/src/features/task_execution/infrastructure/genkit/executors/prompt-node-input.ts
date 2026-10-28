import {type TaskRunContext} from "../../../domain/executors/node-executor.js";
import {mediaDataUrlFor} from "../runner/media-value-loader.js";
import {type ResolvedEmployee, type WorkflowNode} from "../runner/task-definition.js";
import {type PromptNodeInput, type StructuredOutputField} from "./prompt-node-types.js";
import {generationOptionsFrom} from "../../../../language_models/domain/entities/generation-options.js";

export async function promptInputFor(
  node: WorkflowNode,
  runContext: TaskRunContext,
  employee?: ResolvedEmployee,
): Promise<PromptNodeInput> {
  const config = promptConfigFor(node);
  const instruction = await resolvedInstructionFor(node, runContext);
  return {
    teamId: runContext.teamId,
    instruction: instruction.text,
    languageModelId: config.languageModelId,
    generationOptions: generationOptionsFrom(config.generationOptions),
    outputType: config.outputType,
    choices: config.choices.map((choice) => runContext.templateExpressionResolver.resolveText(choice)),
    structuredFields: config.structuredFields,
    mediaUrls: instruction.mediaUrls,
    employee,
  };
}

async function resolvedInstructionFor(
  node: WorkflowNode,
  runContext: TaskRunContext,
): Promise<ResolvedPromptInstruction> {
  return resolvedInstruction(rawInstructionFor(node), runContext);
}

/** Löst die Workflow-Werte einer Anweisung auf; Bilder gehen als eigene Medienteile mit, nicht als Text. */
export async function resolvedInstruction(
  instruction: string,
  runContext: TaskRunContext,
): Promise<ResolvedPromptInstruction> {
  return {
    text: runContext.templateExpressionResolver
      .resolveTextWithoutMediaReferences(instruction).trim(),
    mediaUrls: await mediaUrlsFor(instruction, runContext),
  };
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

async function mediaUrlsFor(
  template: string,
  runContext: TaskRunContext,
): Promise<string[]> {
  return Promise.all(runContext.templateExpressionResolver
    .resolveMediaReferences(template)
    .map((reference) => mediaDataUrlFor(
      reference,
      runContext.teamId,
      runContext.fileContentReader,
    )));
}

export type ResolvedPromptInstruction = {text: string; mediaUrls: string[]};

export function validStructuredFields(
  fields: StructuredOutputField[],
): StructuredOutputField[] {
  return fields.filter((field) => field.name.trim().length > 0);
}
