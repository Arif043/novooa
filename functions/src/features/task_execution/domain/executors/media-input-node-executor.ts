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
    const definition = mediaInputDefinitionFor(node.config);
    validateMediaInputDefinition(definition);
    return waitingForInteractionNode(
      node,
      {},
      mediaInputInteraction({
        ...definition,
        instruction: runContext.templateExpressionResolver.resolveText(definition.instruction),
      }),
    );
  },
};

function mediaInputDefinitionFor(
  config: Parameters<NodeExecutor["execute"]>[0]["config"],
) {
  if (config.primitive !== "mediaInput") {
    throw new Error("MediaInput-Konfiguration fehlt.");
  }
  return {
    instruction: config.instruction,
    documentScanEnabled: config.documentScanEnabled ?? false,
  };
}
