import {
  validateDialogInputDefinition,
} from "../../../domain/entities/dialog-input.js";
import {
  type NodeExecutor,
  waitingForApprovalNode,
} from "../runner/node-executor.js";

export const dialogInputNodeExecutor: NodeExecutor = {
  primitive: "dialogInput",
  async execute(input, runContext) {
    const definition = dialogInputDefinitionFor(input.node.config);
    validateDialogInputDefinition(definition);
    return waitingForApprovalNode(
      input.node,
      {},
      runContext.resolveTemplates(definition.instruction),
      definition,
    );
  },
};

function dialogInputDefinitionFor(
  config: Parameters<NodeExecutor["execute"]>[0]["node"]["config"],
) {
  if (config.primitive !== "dialogInput") {
    throw new Error("DialogInput-Konfiguration fehlt.");
  }
  return {instruction: config.instruction, fields: config.fields};
}
