import {type Genkit, type ModelArgument} from "genkit";
import {type AssistantResponder} from "../../../../assistant/domain/repositories/assistant-responder.js";
import {
  GenkitAssistantResponder,
} from "../../../../assistant/infrastructure/genkit/genkit-assistant-responder.js";
import {
  type ModelCatalogSearchToolDependencies,
} from "../../../../machine_learning/infrastructure/genkit/model-catalog-search-tool.js";
import {type TaskBuilderAssistantResponse} from "../../../domain/entities/task-builder-assistant-response.js";
import {createTaskBuilderSubagentTools} from "./subagents/task-builder-subagent-tools.js";
import {taskBuilderOrchestratorInstructions} from "./task-builder-orchestrator-prompt.js";
import {rawOutputSchema, taskBuilderOutputFromModelOutput} from "./task-builder-assistant-output.js";

export type TaskBuilderAssistantResponderDependencies = {
  ai: Genkit;
  model: ModelArgument;
  modelConfig: Record<string, unknown>;
  modelCatalogSearch: ModelCatalogSearchToolDependencies;
};

/** Orchestrator: führt das Gespräch und delegiert an die Subagenten des Aufgabenstudios. */
export function createTaskBuilderAssistantResponder(
  dependencies: TaskBuilderAssistantResponderDependencies,
): AssistantResponder<TaskBuilderAssistantResponse> {
  const {ai, model} = dependencies;
  return new GenkitAssistantResponder({
    ai,
    model,
    label: "Aufgabenstudio-Agent",
    instructions: taskBuilderOrchestratorInstructions,
    tools: createTaskBuilderSubagentTools(ai, model, dependencies.modelCatalogSearch),
    modelConfig: dependencies.modelConfig,
    outputSchema: rawOutputSchema,
    responseFromOutput: taskBuilderOutputFromModelOutput,
    maxTurns: 8,
  });
}
