import {
  type NodeExecutor,
  executedNode,
} from "../task-runner/node-executor.js";

export const stringInputNodeExecutor: NodeExecutor = {
  primitive: "stringInput",
  async execute(input) {
    const value = input.node.config.primitive === "stringInput"
      ? input.node.config.value
      : "";
    return executedNode(input.node, value);
  },
};
