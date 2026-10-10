import {
  type ForEachNodeConfig,
  type NodeExecutionResult,
  type WorkflowGraph,
  type WorkflowOutput,
} from "../entities/task.js";
import {valueAtJsonPointer} from "../services/json-pointer.js";
import {type WorkflowExecutionScope} from "./node-executor.js";

export type ForEachExecutionRequest = {
  config: ForEachNodeConfig;
  items: unknown;
  runGraph: (
    graph: WorkflowGraph,
    scope: WorkflowExecutionScope,
  ) => Promise<NodeExecutionResult[]>;
};

export async function executeForEach(
  request: ForEachExecutionRequest,
): Promise<unknown[]> {
  const items = itemsFor(request.items, request.config.itemsPointer);
  validateGraph(request.config.graph.nodes);
  const results: unknown[] = [];
  for (const [index, item] of items.entries()) {
    try {
      const graphResults = await request.runGraph(
        graphFor(request.config.graph),
        {iteration: {index, value: item}},
      );
      results.push(outputsOf(graphResults, request.config.graph.nodes));
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unbekannter Fehler";
      throw new Error(`Iteration ${index} ist fehlgeschlagen: ${message}`);
    }
  }
  return results;
}

function itemsFor(value: unknown, pointer: string): unknown[] {
  const items = valueAtJsonPointer(value, pointer);
  if (!Array.isArray(items)) {
    throw new Error("Der JSON-Pointer verweist nicht auf ein Array.");
  }
  return items;
}

function validateGraph(nodes: readonly {primitive: string}[]): void {
  if (nodes.some((node) => node.primitive === "forEach")) {
    throw new Error("Verschachtelte Für-jedes-Element-Bausteine werden noch nicht unterstützt.");
  }
  if (nodes.some(isPausingNode)) {
    throw new Error("Pausierende Bausteine sind im Unterplan nicht erlaubt.");
  }
}

function isPausingNode(node: {primitive: string}): boolean {
  return node.primitive === "humanApproval" ||
    node.primitive === "dialogInput" ||
    node.primitive === "mediaInput";
}

function graphFor(config: ForEachNodeConfig["graph"]): WorkflowGraph {
  return config as WorkflowGraph;
}

/**
 * Ein Ergebnis je Runde: alle benannten Werte der Bausteine im Unterplan
 * flach unter ihrem Namen, wie in Vorlagen (`{name: wert}`).
 */
function outputsOf(
  results: readonly NodeExecutionResult[],
  nodes: readonly {id: string; outputs?: readonly WorkflowOutput[]}[],
): Record<string, unknown> {
  const resultByNodeId = new Map(results.map((result) => [result.nodeId, result]));
  return Object.fromEntries(nodes.flatMap((node) => {
    const result = resultByNodeId.get(node.id);
    if (result?.status !== "executed") return [];
    return (node.outputs ?? [])
      .filter(({key, name}) => result.outputs[key] !== undefined && name.trim())
      .map(({key, name}) => [name.trim(), result.outputs[key]?.value]);
  }));
}
