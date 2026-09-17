import {
  type ForEachNodeConfig,
  type NodeExecutionResult,
  type NodeOutputValue,
  type WorkflowGraph,
} from "../entities/task.js";
import {valueAtJsonPointer} from "../services/json-pointer.js";
import {type WorkflowGraphInput} from "./node-executor.js";

export type ForEachExecutionRequest = {
  config: ForEachNodeConfig;
  inputValue: NodeOutputValue | undefined;
  runGraph: (
    graph: WorkflowGraph,
    input: WorkflowGraphInput,
  ) => Promise<NodeExecutionResult[]>;
};

export async function executeForEach(
  request: ForEachExecutionRequest,
): Promise<unknown[]> {
  if (request.inputValue?.type !== "json") {
    throw new Error("Für jedes Element benötigt einen JSON-Eingang.");
  }
  const items = itemsFor(request.inputValue.value, request.config.itemsPointer);
  validateGraph(request.config.graph.nodes);
  const results: unknown[] = [];
  for (const [index, item] of items.entries()) {
    try {
      const graphResults = await request.runGraph(
        graphFor(request.config.graph),
        {
          initialValue: {type: "json", value: item},
          scope: {iteration: {index, value: item}},
        },
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

function outputsOf(
  results: readonly NodeExecutionResult[],
  nodes: readonly {id: string; referenceName: string}[],
): Record<string, unknown> {
  const resultByNodeId = new Map(results.map((result) => [result.nodeId, result]));
  return Object.fromEntries(nodes.flatMap((node) => {
    const result = resultByNodeId.get(node.id);
    if (result?.status !== "executed") return [];
    const name = node.referenceName.trim() || node.id;
    return [[name, Object.fromEntries(
      Object.entries(result.outputs).map(([key, output]) => [key, output.value]),
    )]];
  }));
}
