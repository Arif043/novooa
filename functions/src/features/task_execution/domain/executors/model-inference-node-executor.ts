import {err, ok, Result} from "neverthrow";
import {
  executedNode,
  type NodeExecutor,
  type NodeResultOrFailure,
} from "./node-executor.js";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
import {type ModelInferenceInputMapping} from "../entities/task.js";
import {modelInputFromWorkflowMapping} from "../services/model-input-from-workflow-mapping.js";
import {modelOutputValuesFor} from "./model-output-values.js";

type Node = Parameters<NodeExecutor["execute"]>[0];
type RunContext = Parameters<NodeExecutor["execute"]>[1];
type ModelNodeConfig = Extract<Node["config"], {primitive: "modelInference" | "textToSpeech" | "speechToText"}>;

export const modelInferenceNodeExecutor: NodeExecutor = {
  primitive: "modelInference",
  execute: executeModelInferenceNode,
};

export async function executeModelInferenceNode(node: Node, runContext: RunContext): Promise<NodeResultOrFailure> {
  const config = modelConfigFor(node);
  if (config === undefined) return err(nodeFailures.configurationMissing(node.primitive));
  const requestOrFailure = modelIdFor(config)
    .andThen((modelId) => settingsFor(config, runContext).map((settings) => ({modelId, settings})));
  if (requestOrFailure.isErr()) return err(requestOrFailure.error);
  const inputsOrFailure = await inputsFor(config, runContext);
  if (inputsOrFailure.isErr()) return err(inputsOrFailure.error);
  const result = await runContext.modelInference.execute({
    teamId: runContext.teamId,
    ...requestOrFailure.value,
    inputs: inputsOrFailure.value,
    transformationBindings: runContext.scope,
  });
  return (await modelOutputValuesFor(result, runContext)).map((outputs) => executedNode(node, outputs));
}

function modelConfigFor(node: Node): ModelNodeConfig | undefined {
  const config = node.config;
  const isModelNode = config.primitive === "modelInference" ||
    config.primitive === "textToSpeech" || config.primitive === "speechToText";
  return isModelNode ? config : undefined;
}

function modelIdFor(config: ModelNodeConfig): Result<string, NodeFailure> {
  const modelId = config.modelId.trim();
  return modelId.length === 0 ? err(nodeFailures.settingMissing("model")) : ok(modelId);
}

async function inputsFor(config: ModelNodeConfig, runContext: RunContext) {
  const mappingsOrFailure = validMappings(config.inputMappings);
  if (mappingsOrFailure.isErr()) return err(mappingsOrFailure.error);
  const inputs = await Promise.all(mappingsOrFailure.value.map(async (mapping) => (await modelInputFromWorkflowMapping(
    mapping,
    runContext.templateExpressionResolver.resolveValue(mapping.workflowMapping),
    runContext.teamId,
    runContext.fileContentReader,
  )).map((input) => ({name: mapping.modelInputName, ...input}))));
  return Result.combine(inputs);
}

function validMappings(mappings: ModelInferenceInputMapping[]): Result<ModelInferenceInputMapping[], NodeFailure> {
  const names = new Set<string>();
  for (const mapping of mappings) {
    if (!mapping.modelInputName.trim() || !mapping.workflowMapping.trim()) {
      return err(nodeFailures.settingMissing("modelInputMapping"));
    }
    if (names.has(mapping.modelInputName)) return err(nodeFailures.settingInvalid("modelInputDuplicate", mapping.modelInputName));
    names.add(mapping.modelInputName);
  }
  return ok(mappings);
}

function settingsFor(config: ModelNodeConfig, runContext: RunContext): Result<Record<string, unknown>, NodeFailure> {
  const parameters = config.settings ?? [];
  const names = parameters.map((parameter) => parameter.name);
  const invalid = parameters.find((parameter, index) =>
    !parameter.name.trim() || !parameter.valueTemplate.trim() || names.indexOf(parameter.name) !== index);
  if (invalid !== undefined) return err(nodeFailures.settingInvalid("modelParameter", invalid.name));
  return ok(Object.fromEntries(parameters.map((parameter) => [
    parameter.name, runContext.templateExpressionResolver.resolveValue(parameter.valueTemplate),
  ])));
}
