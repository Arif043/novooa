import {type FileReference, type WorkflowInputValue} from "../../../domain/entities/workflow-value.js";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type WorkflowGraph,
  type WorkflowNode,
} from "./task-definition.js";
import {type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";

const expressionPattern = /\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}/g;
const isolatedExpressionPattern = /^\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}$/;

export type TemplateExpressionContext = {
  scope: WorkflowExecutionScope;
  /**
   * Der einzige, graph-weite Namensraum aller Ausgabewerte: jeder Wert eines
   * Bausteins unter seinem Namen aus `outputs` (`value` → `{{Datensatz}}`,
   * `found` → `{{Gefunden}}`, Prompt-Feld `summe` → `{{Summe}}`). Eine
   * Adressierung über den Knotennamen
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

  /**
   * Der Wert hinter einem Pfad samt Typ, für `workflow_input` im Script. Nur ein ganzer Ausgabewert kennt
   * seinen Typ; Pfade hinein, das Schleifenelement und Werte der äußeren Ebene gelten als `json`.
   */
  typedValueAt(path: string): WorkflowInputValue | undefined {
    const [name, ...valuePath] = path.split(".");
    const output = valuePath.length === 0 ? this.contextFor().flatOutputs[name] : undefined;
    if (output !== undefined && !this.isShadowedByScope(name)) return {type: output.type, value: output.value};
    const value = this.valueAt(path);
    return value === undefined ? undefined : {type: "json", value};
  }

  private isShadowedByScope(name: string): boolean {
    return valueAtPath(this.contextFor().scope, [name]) !== undefined;
  }

  private valueAt(path: string): unknown {
    const context = this.contextFor();
    const segments = path.split(".");
    return valueAtPath(context.scope, segments) ??
      flatOutputAt(context.flatOutputs, segments) ??
      valueAtPath(context.scope.global, segments);
  }
}

export function templateExpressionContextFor(
  graph: WorkflowGraph,
  results: Map<string, NodeExecutionResult>,
  scope: WorkflowExecutionScope = {},
): TemplateExpressionContext {
  return {scope, flatOutputs: flatOutputsFor(graph.nodes, results)};
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
 * Baut den flachen Namensraum aus den Ausführungsergebnissen: Bei jedem
 * Baustein bestimmt `outputs`, unter welchem Namen welcher Wert steht —
 * auch bei strukturierter Prompt-Ausgabe, Dialogeingabe und Script mit
 * `workflow_output`, deren Schlüssel der Feldname ist.
 */
export function flatOutputsFor(
  nodes: WorkflowNode[],
  results: Map<string, NodeExecutionResult>,
): Record<string, NodeOutputValue> {
  const flatOutputs: Record<string, NodeOutputValue> = {};
  for (const node of nodes) {
    const result = results.get(node.id);
    if (result) mergeNamedOutputs(flatOutputs, node, result.outputs);
  }
  return flatOutputs;
}

function mergeNamedOutputs(
  flatOutputs: Record<string, NodeOutputValue>,
  node: WorkflowNode,
  outputs: Record<string, NodeOutputValue>,
): void {
  for (const {key, name} of node.outputs ?? []) {
    const output = outputs[key];
    if (output !== undefined && name.trim()) flatOutputs[name.trim()] = output;
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
