import {executedNode, type NodeExecutor, singleParentOutput} from "../runner/node-executor.js";
import {valueAtJsonPointer} from "../runner/json-pointer.js";
import {type NodeExecutionResult, type TaskDefinition} from "../runner/task-definition.js";

export const forEachNodeExecutor: NodeExecutor = {
  primitive: "forEach",
  async execute(input, runContext) {
    const config = configFor(input.node);
    const value = singleParentOutput(input.parentOutputs);
    if (value?.type !== "json") throw new Error("Für jedes Element benötigt einen JSON-Eingang.");
    const items = itemsFor(value.value, config.itemsPointer);
    validateSubgraph(config.graph.nodes);
    const results: unknown[] = [];
    for (const [index, item] of items.entries()) {
      try {
        const subgraphResults = await runContext.runSubgraph(subgraphTask(input.node.id, config), input.context, {type: "json", value: item});
        results.push(primaryValueOf(subgraphResults));
      } catch (error) {
        const message = error instanceof Error ? error.message : "Unbekannter Fehler";
        throw new Error(`Iteration ${index} ist fehlgeschlagen: ${message}`);
      }
    }
    return executedNode(input.node, {value: {type: "json", value: results}});
  },
};

function configFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]) {
  if (node.config.primitive !== "forEach") throw new Error("Für-jedes-Element-Konfiguration fehlt.");
  return node.config;
}

function itemsFor(value: unknown, pointer: string): unknown[] {
  const items = valueAtJsonPointer(value, pointer);
  if (!Array.isArray(items)) throw new Error("Der JSON-Pointer verweist nicht auf ein Array.");
  return items;
}

function validateSubgraph(nodes: readonly {primitive: string}[]): void {
  if (nodes.some((node) => node.primitive === "forEach")) throw new Error("Verschachtelte Für-jedes-Element-Bausteine werden noch nicht unterstützt.");
  if (nodes.some((node) => node.primitive === "humanApproval" || node.primitive === "dialogInput" || node.primitive === "mediaInput")) throw new Error("Pausierende Bausteine sind im Unterplan nicht erlaubt.");
}

function subgraphTask(nodeId: string, config: ReturnType<typeof configFor>) {
  return {
    id: `${nodeId}:forEach`, title: "Für jedes Element", objective: "",
    nodes: config.graph.nodes as TaskDefinition["nodes"], edges: config.graph.edges,
  };
}

function primaryValueOf(results: readonly NodeExecutionResult[]): unknown {
  for (let index = results.length - 1; index >= 0; index -= 1) {
    const output = results[index].outputs.value;
    if (output !== undefined) return output.value;
  }
  return null;
}
