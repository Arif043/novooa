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
      nodeId: input.node.id,
      config,
      inputValue: singleParentOutput(input.parentOutputs),
      runSubgraph: (task, initialValue) => runContext.runSubgraph(
        task,
        input.context,
        initialValue,
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
