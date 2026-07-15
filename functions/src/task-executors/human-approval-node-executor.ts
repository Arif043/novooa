import {
  type NodeExecutor,
  parentOutputFor,
  textOutputs,
  waitingForApprovalNode,
} from "../task-runner/node-executor.js";

export const humanApprovalNodeExecutor: NodeExecutor = {
  primitive: "humanApproval",
  async execute(input, runContext) {
    const output = parentOutputFor(
      input.node,
      runContext.task,
      runContext.results,
    );
    const reviewOutput = runContext.resolveTemplates(output);
    return waitingForApprovalNode(
      input.node,
      textOutputs(reviewOutput),
      runContext.resolveTemplates(messageFor(input.node.config)),
    );
  },
};

function messageFor(config: Parameters<NodeExecutor["execute"]>[0]["node"]["config"]) {
  if (config.primitive !== "humanApproval") {
    return "Aufgabe wartet auf Freigabe.";
  }
  return config.instruction.trim() || "Aufgabe wartet auf Freigabe.";
}
