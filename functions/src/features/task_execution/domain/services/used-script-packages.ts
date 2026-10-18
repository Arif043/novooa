import {normalizedScriptPackages} from "./script-packages.js";
import {allNodesOf, type GraphNode, record} from "./task-graph-nodes.js";

/** Die normalisierten Paketlisten aller Script-Bausteine eines Plans, auch in Zweigen und Schleifen. */
export function scriptPackageListsOf(graph: {nodes: readonly GraphNode[]}): string[][] {
  return allNodesOf(graph)
    .map((node) => record(node.config))
    .filter((config) => config.primitive === "script" && Array.isArray(config.packages))
    .map((config) => normalizedScriptPackages((config.packages as unknown[]).filter(isText)))
    .filter((packages) => packages.length > 0);
}

function isText(value: unknown): value is string {
  return typeof value === "string";
}
