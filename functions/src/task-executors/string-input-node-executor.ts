import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "../task-runner/node-executor.js";

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
