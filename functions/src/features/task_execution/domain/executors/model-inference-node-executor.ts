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
  execute: executeModelInferenceNode,
};

export async function executeModelInferenceNode(
  node: Parameters<NodeExecutor["execute"]>[0],
  runContext: Parameters<NodeExecutor["execute"]>[1],
) {
  const inputs = await inputsFor(node, runContext);
  const result = await runContext.modelInference.execute({
    teamId: runContext.teamId,
    modelId: modelIdFor(node),
    inputs,
    outputParameters: outputParametersFor(node),
    settings: settingsFor(node, runContext),
    transformationBindings: runContext.scope,
  });
  return executedNode(node, await outputsFor(result, runContext));
}

type ModelNodeConfig = Extract<Parameters<NodeExecutor["execute"]>[0]["config"], {
  primitive: "modelInference" | "textToSpeech" | "speechToText";
}>;

function modelConfigFor(node: Parameters<NodeExecutor["execute"]>[0]): ModelNodeConfig {
  if (
    node.config.primitive !== "modelInference" &&
    node.config.primitive !== "textToSpeech" &&
    node.config.primitive !== "speechToText"
  ) {
    throw new Error("Modell-Inferenz-Konfiguration fehlt.");
  }
  return node.config;
}

function modelIdFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  const config = modelConfigFor(node);
  if (config.modelId.trim().length === 0) {
    throw new Error("Für die Modell-Inferenz wurde kein Modell ausgewählt.");
  }
  return config.modelId.trim();
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
  const config = modelConfigFor(node);
  const names = new Set<string>();
  for (const mapping of config.inputMappings) {
    if (!mapping.modelInputName.trim() || !mapping.workflowMapping.trim()) {
      throw new Error("Eine Modelleingabe ist nicht vollständig zugeordnet.");
    }
    if (names.has(mapping.modelInputName)) {
      throw new Error(`Die Modelleingabe ${mapping.modelInputName} ist mehrfach zugeordnet.`);
    }
    names.add(mapping.modelInputName);
  }
  return config.inputMappings;
}

function outputParametersFor(node: Parameters<NodeExecutor["execute"]>[0]) {
  const config = modelConfigFor(node);
  const identities = new Set<string>();
  for (const parameter of config.outputParameters ?? []) {
    if (!parameter.outputName.trim() || !parameter.name.trim() || !Number.isSafeInteger(parameter.value)) {
      throw new Error("Ein Ausgangsparameter der Modell-Inferenz ist ungültig.");
    }
    const identity = `${parameter.outputName}:${parameter.name}`;
    if (identities.has(identity)) throw new Error(`Der Ausgangsparameter ${parameter.name} ist mehrfach gesetzt.`);
    identities.add(identity);
  }
  return config.outputParameters ?? [];
}

function settingsFor(
  node: Parameters<NodeExecutor["execute"]>[0],
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Record<string, unknown> {
  const values = modelConfigFor(node).settings ?? [];
  const names = new Set<string>();
  return Object.fromEntries(values.map((parameter) => {
    if (!parameter.name.trim() || !parameter.valueTemplate.trim() || names.has(parameter.name)) {
      throw new Error("Ein Modellparameter ist ungültig.");
    }
    names.add(parameter.name);
    return [parameter.name, runContext.templateExpressionResolver.resolveValue(parameter.valueTemplate)];
  }));
}

async function outputsFor(
  result: ModelInferenceResult,
  runContext: Parameters<NodeExecutor["execute"]>[1],
) {
  const outputs = await Promise.all(result.outputs.map(async (output) => [
    output.workflowOutput.name,
    await workflowOutputValueFor(output, runContext),
  ] as const));
  return Object.fromEntries(outputs);
}

async function workflowOutputValueFor(
  output: ModelInferenceResult["outputs"][number],
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<NodeOutputValue> {
  if (output.workflowOutput.type === "audio") {
    return audioOutputValue(output, runContext);
  }
  return {type: output.workflowOutput.type, value: workflowValueForModelOutput(output.value)} as NodeOutputValue;
}

async function audioOutputValue(
  output: ModelInferenceResult["outputs"][number],
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<NodeOutputValue> {
  const audio = audioPayload(output.value);
  const file = await runContext.teamFileStore.writeTeamFile({
    teamId: runContext.teamId,
    content: Uint8Array.from(Buffer.from(audio.dataBase64, "base64")),
    fileName: audio.fileName ?? "sprach-ausgabe.wav",
    contentType: audio.contentType,
    targetFileId: null,
  });
  return {type: "audio", value: file};
}

function audioPayload(value: unknown): {dataBase64: string; contentType: string; fileName?: string} {
  if (!isRecord(value) || typeof value.dataBase64 !== "string" || typeof value.contentType !== "string") {
    throw new Error("Die Audioausgabe des Modells ist ungültig.");
  }
  if (!value.contentType.startsWith("audio/")) {
    throw new Error("Die Audioausgabe des Modells hat keinen Audio-Content-Type.");
  }
  return typeof value.fileName === "string"
    ? {dataBase64: value.dataBase64, contentType: value.contentType, fileName: value.fileName}
    : {dataBase64: value.dataBase64, contentType: value.contentType};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
