import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "./node-executor.js";

export const stringInputNodeExecutor: NodeExecutor = {
  primitive: "stringInput",
  async execute(node, runContext) {
    const value = node.config.primitive === "stringInput"
      ? node.config.value
      : "";
    return executedNode(
      node,
      textOutputs(runContext.resolveTemplates(value)),
    );
  },
};
