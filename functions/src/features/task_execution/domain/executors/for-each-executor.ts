import {
  type ForEachNodeConfig,
  type NodeExecutionResult,
  type NodeOutputValue,
  type TaskDefinition,
} from "../entities/task.js";
import {valueAtJsonPointer} from "../services/json-pointer.js";

export type ForEachExecutionRequest = {
  nodeId: string;
  config: ForEachNodeConfig;
  inputValue: NodeOutputValue | undefined;
  runSubgraph: (
    task: TaskDefinition,
    initialValue: NodeOutputValue,
  ) => Promise<NodeExecutionResult[]>;
};

export async function executeForEach(
  request: ForEachExecutionRequest,
): Promise<unknown[]> {
  if (request.inputValue?.type !== "json") {
    throw new Error("Für jedes Element benötigt einen JSON-Eingang.");
  }
  const items = itemsFor(request.inputValue.value, request.config.itemsPointer);
  validateSubgraph(request.config.graph.nodes);
  const results: unknown[] = [];
  for (const [index, item] of items.entries()) {
    try {
      const subgraphResults = await request.runSubgraph(
        subgraphTask(request.nodeId, request.config),
        {type: "json", value: item},
      );
      results.push(primaryValueOf(subgraphResults));
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

function validateSubgraph(nodes: readonly {primitive: string}[]): void {
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

function subgraphTask(
  nodeId: string,
  config: ForEachNodeConfig,
): TaskDefinition {
  return {
    id: `${nodeId}:forEach`,
    title: "Für jedes Element",
    objective: "",
    nodes: config.graph.nodes as TaskDefinition["nodes"],
    edges: config.graph.edges,
  };
}

function primaryValueOf(results: readonly NodeExecutionResult[]): unknown {
  for (let index = results.length - 1; index >= 0; index -= 1) {
    const output = results[index].outputs.value;
    if (output !== undefined) return output.value;
  }
  return null;
}
