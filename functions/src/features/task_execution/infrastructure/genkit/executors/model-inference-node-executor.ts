import {
  executedNode,
  type NodeExecutor,
} from "../runner/node-executor.js";
import {type ModelInferenceResult} from
  "../../../../machine_learning/domain/repositories/model-inference.js";
import {modelInputForWorkflowValue} from "./workflow-model-input-adapter.js";

export const modelInferenceNodeExecutor: NodeExecutor = {
  primitive: "modelInference",
  async execute(input, runContext) {
    const inputs = await Promise.all(
      input.parentOutputs.map((output) => modelInputForWorkflowValue(
        output.value,
        runContext.teamId,
        runContext.fileContentReader,
      )),
    );
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

function outputsFor(result: ModelInferenceResult) {
  return {
    value: {type: "json" as const, value: serializableResultFor(result)},
    modelId: {type: "string" as const, value: result.modelId},
  };
}

function serializableResultFor(result: ModelInferenceResult) {
  return {
    modelId: result.modelId,
    outputs: result.outputs.map((output) => ({
      name: output.name,
      semantic: output.semantic,
      dataType: output.dataType,
      shape: output.shape,
      dataBase64: Buffer.from(output.bytes).toString("base64"),
    })),
  };
}
