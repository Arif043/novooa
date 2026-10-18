import {ok} from "neverthrow";
import {executeForEach} from "./for-each-executor.js";
import {
  type NodeExecutor,
  executedNode,
} from "./node-executor.js";

export const forEachNodeExecutor: NodeExecutor = {
  primitive: "forEach",
  async execute(node, runContext) {
    const config = configFor(node);
    const results = await executeForEach({
      config,
      items: runContext.templateExpressionResolver.resolveValue(
        config.itemsTemplate ?? "",
      ),
      runGraph: (graph, scope) => runContext.runGraph(
        graph,
        runContext.context,
        scope,
      ),
    });
    return ok(executedNode(node, {value: {type: "json", value: results}}));
  },
};

function configFor(node: Parameters<NodeExecutor["execute"]>[0]) {
  if (node.config.primitive !== "forEach") {
    throw new Error("Für-jedes-Element-Konfiguration fehlt.");
  }
  return node.config;
}
