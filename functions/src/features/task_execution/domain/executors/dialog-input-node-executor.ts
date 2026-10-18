import {nodeFailures} from "../entities/node-failures.js";
import {err, ok} from "neverthrow";
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
  async execute(node, runContext) {
    if (node.config.primitive !== "dialogInput") return err(nodeFailures.configurationMissing(node.primitive));
    const definition = {instruction: node.config.instruction, fields: node.config.fields};
    validateDialogInputDefinition(definition);
    return ok(waitingForInteractionNode(
      node,
      {},
      dialogInputInteraction({
        ...definition,
        instruction: runContext.templateExpressionResolver.resolveText(definition.instruction),
      }),
    ));
  },
};
