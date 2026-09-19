import {executeForEach} from "./for-each-executor.js";
import {
  type NodeExecutor,
  executedNode,
  singleParentOutput,
} from "./node-executor.js";

export const forEachNodeExecutor: NodeExecutor = {
  primitive: "forEach",
  async execute(node, runContext, parentOutputs) {
    const config = configFor(node);
    const results = await executeForEach({
      config,
      inputValue: singleParentOutput(parentOutputs),
      runGraph: (graph, graphInput) => runContext.runGraph(
        graph,
        runContext.context,
        graphInput,
      ),
    });
    return executedNode(node, {value: {type: "json", value: results}});
  },
};

function configFor(node: Parameters<NodeExecutor["execute"]>[0]) {
  if (node.config.primitive !== "forEach") {
    throw new Error("Für-jedes-Element-Konfiguration fehlt.");
  }
  return node.config;
}
