import {err} from "neverthrow";
import {nodeFailures} from "../entities/node-failures.js";
import {executeForEach} from "./for-each-executor.js";
import {
  type NodeExecutor,
  executedNode,
} from "./node-executor.js";

export const forEachNodeExecutor: NodeExecutor = {
  primitive: "forEach",
  async execute(node, runContext) {
    if (node.config.primitive !== "forEach") return err(nodeFailures.configurationMissing(node.primitive));
    const config = node.config;
    const resultsOrFailure = await executeForEach({
      config,
      items: runContext.templateExpressionResolver.resolveValue(
        config.itemsTemplate ?? "",
      ),
      runGraph: (graph, scope) => runContext.runGraph(graph, scope),
    });
    return resultsOrFailure.map((results) => executedNode(node, {value: {type: "json", value: results}}));
  },
};

