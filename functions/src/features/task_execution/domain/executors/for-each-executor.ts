import {err, ok, type Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
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
  ) => Promise<Result<NodeExecutionResult[], NodeFailure>>;
};

export async function executeForEach(
  request: ForEachExecutionRequest,
): Promise<Result<unknown[], NodeFailure>> {
  const itemsOrFailure = itemsFor(request.items, request.config.itemsPointer)
    .andThen((items) => supportedGraph(request.config.graph.nodes).map(() => items));
  if (itemsOrFailure.isErr()) return err(itemsOrFailure.error);
  const results: unknown[] = [];
  for (const [index, item] of itemsOrFailure.value.entries()) {
    const graphResults = await request.runGraph(graphFor(request.config.graph), {iteration: {index, value: item}});
    if (graphResults.isErr()) return err(graphResults.error.withDetail("iteration", String(index)));
    results.push(outputsOf(graphResults.value, request.config.graph.nodes));
  }
  return ok(results);
}

function itemsFor(value: unknown, pointer: string): Result<unknown[], NodeFailure> {
  return valueAtJsonPointer(value, pointer).andThen((items) => Array.isArray(items)
    ? ok(items)
    : err(nodeFailures.valueTypeMismatch("forEachItems", "list")));
}

function supportedGraph(nodes: readonly {primitive: string}[]): Result<void, NodeFailure> {
  if (nodes.some((node) => node.primitive === "forEach")) return err(nodeFailures.forEachUnsupported("nestedForEach"));
  if (nodes.some(isPausingNode)) return err(nodeFailures.forEachUnsupported("pausingBlock"));
  return ok(undefined);
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
