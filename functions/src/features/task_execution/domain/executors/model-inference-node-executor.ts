import {
  executedNode,
  type NodeExecutor,
} from "./node-executor.js";
import {type ModelInferenceResult} from
  "../../../machine_learning/domain/repositories/model-inference.js";
import {modelInputFromWorkflowMapping} from "../services/model-input-from-workflow-mapping.js";
import {workflowValueForTensor} from "../services/tensor-workflow-value.js";

export const modelInferenceNodeExecutor: NodeExecutor = {
  primitive: "modelInference",
  async execute(input, runContext) {
    const inputs = await inputsFor(input, runContext);
    const result = await runContext.modelInference.execute({
      teamId: runContext.teamId,
      modelId: modelIdFor(input.node),
      inputs,
    });
    return executedNode(input.node, outputsFor(result));
  },
};

function modelIdFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]): string {
  if (node.config.primitive !== "modelInference") {
    throw new Error("Modell-Inferenz-Konfiguration fehlt.");
  }
  if (node.config.modelId.trim().length === 0) {
    throw new Error("Für die Modell-Inferenz wurde kein Modell ausgewählt.");
  }
  return node.config.modelId.trim();
}

async function inputsFor(
  input: Parameters<NodeExecutor["execute"]>[0],
  runContext: Parameters<NodeExecutor["execute"]>[1],
) {
  const mappings = mappingsFor(input.node);
  return Promise.all(mappings.map(async (mapping) => ({
    name: mapping.modelInputName,
    ...await modelInputFromWorkflowMapping(
      mapping,
      runContext.resolveTemplateValue(mapping.workflowMapping),
      runContext.teamId,
      runContext.fileContentReader,
    ),
  })));
}

function mappingsFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]) {
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

function outputsFor(result: ModelInferenceResult) {
  const values = Object.fromEntries(
    result.outputs.map((output) => [output.name, workflowValueForTensor(output)]),
  );
  return {
    value: {type: "json" as const, value: values},
    modelId: {type: "string" as const, value: result.modelId},
    ...Object.fromEntries(
      result.outputs.map((output) => [
        output.name,
        {type: "json" as const, value: workflowValueForTensor(output)},
      ]),
    ),
  };
}
