import {
  executedNode,
  type NodeExecutor,
} from "./node-executor.js";
import {type ModelInferenceResult} from
  "../../../machine_learning/domain/repositories/model-inference.js";
import {type NodeOutputValue} from "../entities/workflow-value.js";
import {modelInputFromWorkflowMapping} from "../services/model-input-from-workflow-mapping.js";
import {workflowValueForModelOutput} from "../services/tensor-workflow-value.js";

export const modelInferenceNodeExecutor: NodeExecutor = {
  primitive: "modelInference",
  async execute(node, runContext) {
    const inputs = await inputsFor(node, runContext);
    const result = await runContext.modelInference.execute({
      teamId: runContext.teamId,
      modelId: modelIdFor(node),
      inputs,
      outputParameters: outputParametersFor(node),
      transformationBindings: runContext.scope,
    });
    return executedNode(node, outputsFor(result));
  },
};

function modelIdFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  if (node.config.primitive !== "modelInference") {
    throw new Error("Modell-Inferenz-Konfiguration fehlt.");
  }
  if (node.config.modelId.trim().length === 0) {
    throw new Error("Für die Modell-Inferenz wurde kein Modell ausgewählt.");
  }
  return node.config.modelId.trim();
}

async function inputsFor(
  node: Parameters<NodeExecutor["execute"]>[0],
  runContext: Parameters<NodeExecutor["execute"]>[1],
) {
  const mappings = mappingsFor(node);
  return Promise.all(mappings.map(async (mapping) => ({
    name: mapping.modelInputName,
    ...await modelInputFromWorkflowMapping(
      mapping,
      runContext.templateExpressionResolver.resolveValue(mapping.workflowMapping),
      runContext.teamId,
      runContext.fileContentReader,
    ),
  })));
}

function mappingsFor(node: Parameters<NodeExecutor["execute"]>[0]) {
  if (node.config.primitive !== "modelInference") {
    throw new Error("Modell-Inferenz-Konfiguration fehlt.");
  }
  const names = new Set<string>();
  for (const mapping of node.config.inputMappings) {
    if (!mapping.modelInputName.trim() || !mapping.workflowMapping.trim()) {
      throw new Error("Eine Modelleingabe ist nicht vollständig zugeordnet.");
    }
    if (names.has(mapping.modelInputName)) {
      throw new Error(`Die Modelleingabe ${mapping.modelInputName} ist mehrfach zugeordnet.`);
    }
    names.add(mapping.modelInputName);
  }
  return node.config.inputMappings;
}

function outputParametersFor(node: Parameters<NodeExecutor["execute"]>[0]) {
  if (node.config.primitive !== "modelInference") {
    throw new Error("Modell-Inferenz-Konfiguration fehlt.");
  }
  const identities = new Set<string>();
  for (const parameter of node.config.outputParameters ?? []) {
    if (!parameter.outputName.trim() || !parameter.name.trim() || !Number.isSafeInteger(parameter.value)) {
      throw new Error("Ein Ausgangsparameter der Modell-Inferenz ist ungültig.");
    }
    const identity = `${parameter.outputName}:${parameter.name}`;
    if (identities.has(identity)) throw new Error(`Der Ausgangsparameter ${parameter.name} ist mehrfach gesetzt.`);
    identities.add(identity);
  }
  return node.config.outputParameters ?? [];
}

function outputsFor(result: ModelInferenceResult) {
  return Object.fromEntries(result.outputs.map((output) => [
    output.workflowOutput.name,
    workflowOutputValueFor(output),
  ]));
}

function workflowOutputValueFor(
  output: ModelInferenceResult["outputs"][number],
): NodeOutputValue {
  if (output.workflowOutput.type !== "json") {
    throw new Error(`Der Workflow-Typ ${output.workflowOutput.type} wird noch nicht unterstützt.`);
  }
  return {type: "json", value: workflowValueForModelOutput(output.value)};
}
