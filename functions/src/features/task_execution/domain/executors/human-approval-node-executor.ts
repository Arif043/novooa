import {ok} from "neverthrow";
import {
  type NodeExecutor,
  textOutputs,
  waitingForInteractionNode,
} from "./node-executor.js";
import {approvalInteraction} from
  "../entities/task-run-interaction.js";

export const humanApprovalNodeExecutor: NodeExecutor = {
  primitive: "humanApproval",
  async execute(node, runContext) {
    const reviewOutput = runContext.templateExpressionResolver.resolveText(
      reviewTemplateFor(node.config),
    );
    return ok(waitingForInteractionNode(
      node,
      textOutputs(reviewOutput),
      approvalInteraction(runContext.templateExpressionResolver.resolveText(messageFor(node.config))),
    ));
  },
};

function messageFor(config: Parameters<NodeExecutor["execute"]>[0]["config"]) {
  if (config.primitive !== "humanApproval") {
    return "Aufgabe wartet auf Freigabe.";
  }
  return config.instruction.trim() || "Aufgabe wartet auf Freigabe.";
}

function reviewTemplateFor(config: Parameters<NodeExecutor["execute"]>[0]["config"]) {
  return config.primitive === "humanApproval" ? config.reviewTemplate ?? "" : "";
}
