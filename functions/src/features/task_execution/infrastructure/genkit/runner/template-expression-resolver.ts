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
  /**
   * Der einzige, graph-weite Namensraum aller Ausgabewerte: der Hauptwert
   * jedes Bausteins (`outputName`), jeder weitere Wert unter seinem Namen aus
   * `outputFieldNames` (z.B. `{{Gefunden}}`) und jedes Feld eines flachen
   * Bausteins (strukturierte Prompt-Ausgabe, Dialogeingabe, Script mit
   * `workflow_output`). Eine Adressierung über den Knotennamen
   * (`{{Datensatz.found}}`) gibt es nicht.
   */
  flatOutputs: Record<string, NodeOutputValue>;
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

  resolveTextWithoutMediaReferences(template: string): string {
    return template.replace(expressionPattern, (expression, path: string) => {
      const value = this.valueAt(path);
      if (isMediaReference(value)) return "";
      return value === undefined ? expression : textFor(value);
    });
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
      flatOutputAt(context.flatOutputs, segments) ??
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
  return {variables, scope, flatOutputs: flatOutputsFor(graph.nodes, results)};
}

/** Ein einzelnes Segment (`{{eingang}}`) oder ein Dot-Pfad in den eigenen
 * JSON-Wert eines Outputs (`{{bericht.summe}}`, wenn `bericht` ein
 * JSON-Objekt ist). */
function flatOutputAt(
  flatOutputs: TemplateExpressionContext["flatOutputs"],
  path: string[],
): unknown {
  const [name, ...valuePath] = path;
  const output = flatOutputs[name];
  return output === undefined ? undefined : valueAtPath(output.value, valuePath);
}

/**
 * Baut den flachen Namensraum aus den Ausführungsergebnissen. Flache
 * Bausteine (strukturierte Prompt-Ausgabe, Dialogeingabe, Script mit
 * `workflow_output`) haben keinen eigenen Knotennamen; ihre Feldnamen fließen
 * direkt ein. Alle anderen liefern `value` unter ihrem `outputName` und ihre
 * weiteren Werte unter den Namen aus `outputFieldNames`.
 */
export function flatOutputsFor(
  nodes: WorkflowNode[],
  results: Map<string, NodeExecutionResult>,
): Record<string, NodeOutputValue> {
  const flatOutputs: Record<string, NodeOutputValue> = {};
  for (const node of nodes) {
    const result = results.get(node.id);
    if (!result) continue;
    if (hasFlatOutputs(node, result)) {
      mergeFlatFieldOutputs(flatOutputs, result.outputs);
      continue;
    }
    mergeNamedOutputs(flatOutputs, node, result.outputs);
  }
  return flatOutputs;
}

function mergeNamedOutputs(
  flatOutputs: Record<string, NodeOutputValue>,
  node: WorkflowNode,
  outputs: Record<string, NodeOutputValue>,
): void {
  const primaryName = node.outputName.trim() || node.id.replace(/[^\w]/g, "");
  if (primaryName.length > 0 && outputs.value !== undefined) flatOutputs[primaryName] = outputs.value;
  for (const [key, output] of Object.entries(outputs)) {
    const name = node.outputFieldNames?.[key]?.trim();
    if (key !== "value" && name) flatOutputs[name] = output;
  }
}

function hasFlatOutputs(node: WorkflowNode, result: NodeExecutionResult): boolean {
  if (node.config.primitive === "dialogInput") return true;
  // Ein Script ist flach, sobald es per `workflow_output` eigene Ausgaben statt eines `value` liefert.
  if (node.config.primitive === "script") return isScriptWithWorkflowOutputs(result);
  return node.config.primitive === "prompt" && node.config.outputType === "structured";
}

function isScriptWithWorkflowOutputs(result: NodeExecutionResult): boolean {
  return result.outputs.value === undefined && Object.keys(result.outputs).length > 0;
}

function mergeFlatFieldOutputs(
  flatOutputs: TemplateExpressionContext["flatOutputs"],
  outputs: Record<string, NodeOutputValue>,
): void {
  for (const [key, value] of Object.entries(outputs)) {
    if (key === "value") continue;
    flatOutputs[key] = value;
  }
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
