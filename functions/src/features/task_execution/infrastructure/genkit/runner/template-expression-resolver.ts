import {type FileReference} from "../../../domain/entities/workflow-value.js";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type WorkflowGraph,
  type WorkflowNode,
} from "./task-definition.js";
import {
  type TaskVariables,
  type WorkflowExecutionScope,
} from "../../../domain/executors/node-executor.js";

const expressionPattern = /\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}/g;
const isolatedExpressionPattern = /^\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}$/;

export type TemplateExpressionContext = {
  variables: TaskVariables;
  scope: WorkflowExecutionScope;
  nodeOutputs: Record<string, Record<string, NodeOutputValue>>;
};

export class TemplateExpressionResolver {
  constructor(private readonly contextFor: () => TemplateExpressionContext) {}

  resolveText(template: string): string {
    return template.replace(expressionPattern, (expression, path: string) => {
      const value = this.valueAt(path);
      return value === undefined ? expression : textFor(value);
    });
  }

  resolveValue(template: string): unknown {
    const match = template.trim().match(isolatedExpressionPattern);
    return match === null ? this.resolveText(template) : this.valueAt(match[1]);
  }

  resolveMediaReferences(template: string): FileReference[] {
    return Array.from(template.matchAll(expressionPattern))
      .map((match) => this.valueAt(match[1]))
      .filter(isMediaReference);
  }

  private valueAt(path: string): unknown {
    const context = this.contextFor();
    const segments = path.split(".");
    return valueAtPath(context.scope, segments) ??
      nodeOutputAt(context.nodeOutputs, segments) ??
      valueAtPath(context.scope.global, segments) ??
      valueAtPath(context.variables, segments);
  }
}

export function variableTemplateContextFor(
  graph: WorkflowGraph,
  results: Map<string, NodeExecutionResult>,
  variables: TaskVariables,
  scope: WorkflowExecutionScope = {},
): TemplateExpressionContext {
  return {variables, scope, nodeOutputs: nodeOutputScopesFor(graph.nodes, results)};
}

function nodeOutputAt(
  scopes: TemplateExpressionContext["nodeOutputs"],
  path: string[],
): unknown {
  if (path.length < 2) return undefined;
  const [referenceName, outputName, ...valuePath] = path;
  const output = scopes[referenceName]?.[outputName];
  return output === undefined ? undefined : valueAtPath(output.value, valuePath);
}

function nodeOutputScopesFor(
  nodes: WorkflowNode[],
  results: Map<string, NodeExecutionResult>,
) {
  return nodes.reduce<TemplateExpressionContext["nodeOutputs"]>((scopes, node) => {
    const result = results.get(node.id);
    const name = node.referenceName.trim() || node.id.replace(/[^\w]/g, "");
    if (name.length > 0 && result) scopes[name] = result.outputs;
    return scopes;
  }, {});
}

function valueAtPath(value: unknown, path: string[]): unknown {
  return path.reduce<unknown>((current, segment) => {
    if (current === undefined || current === null) return undefined;
    if (Array.isArray(current)) return current[Number(segment)];
    return isRecord(current) ? current[segment] : undefined;
  }, value);
}

function textFor(value: unknown): string {
  return typeof value === "string" ? value : JSON.stringify(value);
}

function isMediaReference(value: unknown): value is FileReference {
  if (!isRecord(value)) return false;
  return typeof value.fileId === "string" &&
    typeof value.versionId === "string" &&
    typeof value.contentType === "string" &&
    value.contentType.startsWith("image/");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
