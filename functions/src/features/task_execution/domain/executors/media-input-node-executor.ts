import {nodeFailures} from "../entities/node-failures.js";
import {err, ok} from "neverthrow";
import {
  validateMediaInputDefinition,
} from "../entities/media-input.js";
import {mediaInputInteraction} from
  "../entities/task-run-interaction.js";
import {
  type NodeExecutor,
  waitingForInteractionNode,
} from "./node-executor.js";

export const mediaInputNodeExecutor: NodeExecutor = {
  primitive: "mediaInput",
  async execute(node, runContext) {
    if (node.config.primitive !== "mediaInput") return err(nodeFailures.configurationMissing(node.primitive));
    const definition = {
      instruction: node.config.instruction,
      documentScanEnabled: node.config.documentScanEnabled ?? false,
    };
    validateMediaInputDefinition(definition);
    return ok(waitingForInteractionNode(
      node,
      {},
      mediaInputInteraction({
        ...definition,
        instruction: runContext.templateExpressionResolver.resolveText(definition.instruction),
      }),
    ));
  },
};
