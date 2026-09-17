import {executeForEach} from "./for-each-executor.js";
import {
  type NodeExecutor,
  executedNode,
  singleParentOutput,
} from "./node-executor.js";

export const forEachNodeExecutor: NodeExecutor = {
  primitive: "forEach",
  async execute(input, runContext) {
    const config = configFor(input.node);
    const results = await executeForEach({
      config,
      inputValue: singleParentOutput(input.parentOutputs),
      runGraph: (graph, graphInput) => runContext.runGraph(
        graph,
        input.context,
        graphInput,
      ),
    });
    return executedNode(input.node, {value: {type: "json", value: results}});
  },
};

function configFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]) {
  if (node.config.primitive !== "forEach") {
    throw new Error("Für-jedes-Element-Konfiguration fehlt.");
  }
  return node.config;
}
