import {
  type NodeExecutor,
  textForParentOutputs,
  textOutputs,
  waitingForInteractionNode,
} from "./node-executor.js";
import {approvalInteraction} from
  "../entities/task-run-interaction.js";

export const humanApprovalNodeExecutor: NodeExecutor = {
  primitive: "humanApproval",
  async execute(input, runContext) {
    const output = textForParentOutputs(input.parentOutputs);
    const reviewOutput = runContext.resolveTemplates(output);
    return waitingForInteractionNode(
      input.node,
      textOutputs(reviewOutput),
      approvalInteraction(runContext.resolveTemplates(messageFor(input.node.config))),
    );
  },
};

function messageFor(config: Parameters<NodeExecutor["execute"]>[0]["node"]["config"]) {
  if (config.primitive !== "humanApproval") {
    return "Aufgabe wartet auf Freigabe.";
  }
  return config.instruction.trim() || "Aufgabe wartet auf Freigabe.";
}
