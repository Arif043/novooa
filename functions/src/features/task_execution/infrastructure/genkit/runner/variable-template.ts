import {type TaskVariables} from "../../../domain/executors/node-executor.js";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type TaskDefinition,
  type WorkflowNode,
} from "./task-definition.js";

const variablePattern = /\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}/g;

export type VariableTemplateContext = {
  variables: TaskVariables;
  nodeOutputs: Record<string, Record<string, NodeOutputValue>>;
};

export function resolveVariableTemplates(
  text: string,
  context: VariableTemplateContext,
): string {
  return text.replace(variablePattern, (match, path: string) => {
    const value = templateValueAt(context, path);
    if (value === undefined) return match;
    return formatVariable(value);
  });
}

export function variableTemplateContextFor(
  task: TaskDefinition,
  results: Map<string, NodeExecutionResult>,
  variables: TaskVariables,
): VariableTemplateContext {
  return {
    variables,
    nodeOutputs: nodeOutputScopesFor(task.nodes, results),
  };
}

function templateValueAt(
  context: VariableTemplateContext,
  path: string,
): unknown {
  const segments = path.split(".");
  const outputValue = nodeOutputAt(context.nodeOutputs, segments);
  if (outputValue !== undefined) return outputValue;
  return valueAtPath(context.variables, segments);
}

function nodeOutputAt(
  scopes: VariableTemplateContext["nodeOutputs"],
  path: string[],
): unknown {
  if (path.length < 2) return undefined;
  const [referenceName, outputName, ...valuePath] = path;
  const output = scopes[referenceName]?.[outputName];
  if (output === undefined) return undefined;
  return valueAtPath(output.value, valuePath);
}

function nodeOutputScopesFor(
  nodes: WorkflowNode[],
  results: Map<string, NodeExecutionResult>,
) {
  return nodes.reduce<VariableTemplateContext["nodeOutputs"]>((scopes, node) => {
    const referenceName = referenceNameFor(node);
    const result = results.get(node.id);
    if (referenceName.length > 0 && result) scopes[referenceName] = result.outputs;
    return scopes;
  }, {});
}

function referenceNameFor(node: WorkflowNode): string {
  if (node.referenceName.trim().length > 0) return node.referenceName.trim();
  return fallbackReferenceNameFor(node);
}

function fallbackReferenceNameFor(node: WorkflowNode): string {
  return node.id.replace(/[^\w]/g, "");
}

function valueAtPath(value: unknown, path: string[]): unknown {
  return path.reduce<unknown>((current, segment) => {
    if (current === undefined || current === null) return undefined;
    if (Array.isArray(current)) return current[Number(segment)];
    if (!isRecord(current)) return undefined;
    return current[segment];
  }, value);
}

function formatVariable(value: unknown): string {
  if (typeof value === "string") return value;
  return JSON.stringify(value);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
