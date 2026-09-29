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
   * Zweitschlüssel fest vorgegebener **Neben**-Ausgaben (z.B. `sender`,
   * `fileId`), genestet unter dem `outputName` des erzeugenden Bausteins —
   * erreichbar per Dot-Pfad, z.B. `{{eingang.sender}}`. Enthält bewusst
   * keinen `value`-Eintrag: Die alte, zweistufige Adressierung des
   * Primärwerts (`{{eingang.value}}`, aus der Zeit vor eindeutigen
   * Einzelnamen) ist abgeschafft — der Primärwert ist ausschließlich über
   * [flatOutputs] als `{{eingang}}` erreichbar.
   */
  nodeOutputs: Record<string, Record<string, NodeOutputValue>>;
  /**
   * Flacher, graph-weiter Namensraum: der primäre Wert jedes benannten
   * Bausteins (`outputName`) sowie jedes einzelne Feld eines Bausteins mit
   * mehreren fachlichen Outputs (strukturierte Prompt-Ausgabe,
   * Dialogeingabe-Felder) — ohne umschließenden Knotennamen, z.B.
   * `{{eingang}}`, `{{Name}}`.
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
  return {variables, scope, ...nodeOutputContextFor(graph.nodes, results)};
}

/** Ein einzelnes Segment (`{{eingang}}`) oder ein Dot-Pfad in den eigenen
 * JSON-Wert eines flachen Outputs (`{{bericht.summe}}`, wenn `bericht` ein
 * JSON-Objekt ist) — nicht zu verwechseln mit den festen Zweitschlüsseln in
 * [nodeOutputAt], die als eigene Einträge in `result.outputs` existieren. */
function flatOutputAt(
  flatOutputs: TemplateExpressionContext["flatOutputs"],
  path: string[],
): unknown {
  const [name, ...valuePath] = path;
  const output = flatOutputs[name];
  return output === undefined ? undefined : valueAtPath(output.value, valuePath);
}

function nodeOutputAt(
  scopes: TemplateExpressionContext["nodeOutputs"],
  path: string[],
): unknown {
  if (path.length < 2) return undefined;
  const [outputName, secondaryKey, ...valuePath] = path;
  const output = scopes[outputName]?.[secondaryKey];
  return output === undefined ? undefined : valueAtPath(output.value, valuePath);
}

/**
 * Baut sowohl den geschachtelten Zweitschlüssel-Namensraum als auch den
 * flachen, graph-weiten Namensraum aus den Ausführungsergebnissen auf.
 * Bausteine mit mehreren fachlichen Outputs (strukturierte Prompt-Ausgabe,
 * Dialogeingabe) verzichten auf einen eigenen Knotennamen — ihre Feldnamen
 * fließen direkt in den flachen Namensraum ein, der generische `value`/
 * `text`-Platzhalter (das ganze Objekt) entfällt dabei bewusst, da er ohne
 * Knotennamen nicht mehr eindeutig adressierbar wäre.
 */
function nodeOutputContextFor(
  nodes: WorkflowNode[],
  results: Map<string, NodeExecutionResult>,
): Pick<TemplateExpressionContext, "nodeOutputs" | "flatOutputs"> {
  const nodeOutputs: TemplateExpressionContext["nodeOutputs"] = {};
  const flatOutputs: TemplateExpressionContext["flatOutputs"] = {};
  for (const node of nodes) {
    const result = results.get(node.id);
    if (!result) continue;
    if (hasFlatOutputs(node)) {
      mergeFlatFieldOutputs(flatOutputs, result.outputs);
      continue;
    }
    const name = node.outputName.trim() || node.id.replace(/[^\w]/g, "");
    if (name.length === 0) continue;
    nodeOutputs[name] = secondaryOutputsOf(result.outputs);
    if (result.outputs.value !== undefined) flatOutputs[name] = result.outputs.value;
  }
  return {nodeOutputs, flatOutputs};
}

function hasFlatOutputs(node: WorkflowNode): boolean {
  if (node.config.primitive === "dialogInput") return true;
  return node.config.primitive === "prompt" && node.config.outputType === "structured";
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

/**
 * Nur die Nebenoutputs eines Bausteins (z.B. `sender`, `fileId`) für die
 * Dot-Pfad-Adressierung unter seinem `outputName` — ohne `value`. Die alte
 * `{{outputName.value}}`-Form ist damit nicht mehr auflösbar, nur noch die
 * flache Kurzform `{{outputName}}` (siehe [flatOutputs]).
 */
function secondaryOutputsOf(
  outputs: Record<string, NodeOutputValue>,
): Record<string, NodeOutputValue> {
  const {value: _primary, ...secondary} = outputs;
  return secondary;
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
