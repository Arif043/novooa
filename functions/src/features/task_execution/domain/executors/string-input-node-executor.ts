import {ok} from "neverthrow";
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
    return ok(executedNode(
      node,
      textOutputs(runContext.templateExpressionResolver.resolveText(value)),
    ));
  },
};
