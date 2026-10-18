import {err, ok, Result} from "neverthrow";
import {type ModelInferenceResult} from
  "../../../machine_learning/domain/repositories/model-inference.js";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
import {mediaReferenceFor, type NodeOutputValue} from "../entities/workflow-value.js";
import {workflowValueForModelOutput} from "../services/tensor-workflow-value.js";
import {type NodeExecutor} from "./node-executor.js";

type RunContext = Parameters<NodeExecutor["execute"]>[1];

/** Die Ausgänge des Modells als Workflow-Werte; Bild- und Audioausgänge werden Team-Dateien. */
export async function modelOutputValuesFor(
  result: ModelInferenceResult,
  runContext: RunContext,
): Promise<Result<Record<string, NodeOutputValue>, NodeFailure>> {
  const outputs = await Promise.all(result.outputs.map(async (output) =>
    (await workflowOutputValueFor(output, runContext)).map((value) => [output.workflowOutput.name, value] as const)));
  return Result.combine(outputs).map((entries) => Object.fromEntries(entries));
}

async function workflowOutputValueFor(
  output: ModelInferenceResult["outputs"][number],
  runContext: RunContext,
): Promise<Result<NodeOutputValue, NodeFailure>> {
  if (output.workflowOutput.type === "audio") return fileOutputValue(output, "audio", runContext);
  if (output.workflowOutput.type === "image") return fileOutputValue(output, "image", runContext);
  return ok({type: output.workflowOutput.type, value: workflowValueForModelOutput(output.value)} as NodeOutputValue);
}

/** Datei aus einer Ausgangstransformation (`audio.wav`, `image.encode`): Base64, Typ, Name. */
async function fileOutputValue(
  output: ModelInferenceResult["outputs"][number],
  kind: "image" | "audio",
  runContext: RunContext,
): Promise<Result<NodeOutputValue, NodeFailure>> {
  const payload = output.value;
  if (!isRecord(payload) || typeof payload.dataBase64 !== "string" || typeof payload.contentType !== "string" ||
    !payload.contentType.startsWith(`${kind}/`)) {
    return err(nodeFailures.modelOutputInvalid(kind));
  }
  const file = await runContext.teamFileStore.writeTeamFile({
    teamId: runContext.teamId,
    content: Uint8Array.from(Buffer.from(payload.dataBase64, "base64")),
    fileName: typeof payload.fileName === "string" ? payload.fileName : defaultFileNames[kind],
    contentType: payload.contentType,
    targetFileId: null,
  });
  return ok(kind === "audio" ? {type: "audio", value: file} : {type: "media", value: mediaReferenceFor(file)});
}

const defaultFileNames = {image: "modell-ausgabe.png", audio: "sprach-ausgabe.wav"};

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
