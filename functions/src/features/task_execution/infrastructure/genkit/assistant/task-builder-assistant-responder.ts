import {promptWithAnswerLanguage} from "../../../../assistant/infrastructure/genkit/assistant-answer-language.js";
import {type Genkit, type ModelArgument} from "genkit";
import {type AssistantResponder} from "../../../../assistant/domain/repositories/assistant-responder.js";
import {
  GenkitAssistantResponder,
} from "../../../../assistant/infrastructure/genkit/genkit-assistant-responder.js";
import {promptWithUrlContext} from "../../../../assistant/infrastructure/genkit/assistant-url-context-prompt.js";
import {
  type ModelCatalogSearchToolDependencies,
} from "../../../../machine_learning/infrastructure/genkit/model-catalog-search-tool.js";
import {type TaskBuilderAssistantResponse} from "../../../domain/entities/task-builder-assistant-response.js";
import {createTaskBuilderSubagentTools} from "./subagents/task-builder-subagent-tools.js";
import {taskBuilderOrchestratorPrompt} from "./task-builder-orchestrator-prompt.js";
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
    systemPrompt: taskBuilderOrchestratorPrompt,
    tools: createTaskBuilderSubagentTools(ai, model, dependencies.modelCatalogSearch),
    modelConfig: dependencies.modelConfig,
    outputSchema: rawOutputSchema,
    promptFromRequest: (request) =>
      promptWithAnswerLanguage(promptWithUrlContext(request.question), request.locale),
    responseFromOutput: taskBuilderOutputFromModelOutput,
    maxTurns: 8,
  });
}
