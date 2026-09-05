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
  async execute(input, runContext) {
    const definition = mediaInputDefinitionFor(input.node.config);
    validateMediaInputDefinition(definition);
    return waitingForInteractionNode(
      input.node,
      {},
      mediaInputInteraction({
        ...definition,
        instruction: runContext.resolveTemplates(definition.instruction),
      }),
    );
  },
};

function mediaInputDefinitionFor(
  config: Parameters<NodeExecutor["execute"]>[0]["node"]["config"],
) {
  if (config.primitive !== "mediaInput") {
    throw new Error("MediaInput-Konfiguration fehlt.");
  }
  return {instruction: config.instruction};
}
