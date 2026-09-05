import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "../../../domain/executors/node-executor.js";

export const stringInputNodeExecutor: NodeExecutor = {
  primitive: "stringInput",
  async execute(input, runContext) {
    const value = input.node.config.primitive === "stringInput"
      ? input.node.config.value
      : "";
    return executedNode(
      input.node,
      textOutputs(runContext.resolveTemplates(value)),
    );
  },
};
