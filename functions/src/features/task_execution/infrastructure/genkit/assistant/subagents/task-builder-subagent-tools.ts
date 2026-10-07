import {type Genkit, type ModelArgument, type ToolArgument} from "genkit";
import {DelegationBudget} from "../../../../../assistant/infrastructure/genkit/subagents/delegation-budget.js";
import {defineSubagentTool} from "../../../../../assistant/infrastructure/genkit/subagents/subagent-tool.js";
import {
  defineModelCatalogSearchTool,
  type ModelCatalogSearchToolDependencies,
} from "../../../../../machine_learning/infrastructure/genkit/model-catalog-search-tool.js";
import {modelCatalogSubagentSpec} from "../../../../../machine_learning/infrastructure/genkit/model-catalog-subagent.js";
import {pythonScriptSubagentSpec} from "./python-script-subagent.js";
import {requirementsAnalysisSubagentSpec} from "./requirements-analysis-subagent.js";

/** Jede Delegation ist ein eigener Modellaufruf; fünf halten das Relay-Timeout (120 s) ein. */
const maxDelegationsPerRequest = 5;

/**
 * Baut die Subagenten des Aufgabenstudio-Orchestrators für genau eine Anfrage:
 * Modell und Delegationsbudget gelten nur für diese Anfrage.
 */
export function createTaskBuilderSubagentTools(
  ai: Genkit,
  model: ModelArgument,
  modelCatalogSearch: ModelCatalogSearchToolDependencies,
): ToolArgument[] {
  const budget = new DelegationBudget(maxDelegationsPerRequest);
  const searchTool = defineModelCatalogSearchTool(ai, modelCatalogSearch);
  return [
    defineSubagentTool(ai, requirementsAnalysisSubagentSpec(model), budget),
    defineSubagentTool(ai, modelCatalogSubagentSpec(model, searchTool), budget),
    defineSubagentTool(ai, pythonScriptSubagentSpec(model), budget),
  ];
}
