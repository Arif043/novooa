import {
  validateDialogInputDefinition,
} from "../entities/dialog-input.js";
import {
  type NodeExecutor,
  waitingForInteractionNode,
} from "./node-executor.js";
import {dialogInputInteraction} from
  "../entities/task-run-interaction.js";

export const dialogInputNodeExecutor: NodeExecutor = {
  primitive: "dialogInput",
  async execute(input, runContext) {
    const definition = dialogInputDefinitionFor(input.node.config);
    validateDialogInputDefinition(definition);
    return waitingForInteractionNode(
      input.node,
      {},
      dialogInputInteraction({
        ...definition,
        instruction: runContext.resolveTemplates(definition.instruction),
      }),
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
