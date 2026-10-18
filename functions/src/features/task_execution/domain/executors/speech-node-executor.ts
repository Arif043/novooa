import {ok} from "neverthrow";
import {executedNode, type NodeExecutor} from "./node-executor.js";
import {executeModelInferenceNode} from "./model-inference-node-executor.js";
import {fileReferenceFor} from "../services/file-output-values.js";

/**
 * Text vorlesen: Mit gewähltem Sprachmodell (`languageModelId`) spricht ein verbundener
 * Anbieter (Google AI, ElevenLabs, OpenAI-kompatibel); sonst läuft das ONNX-Modell.
 */
export const textToSpeechNodeExecutor: NodeExecutor = {
  primitive: "textToSpeech",
  execute: async (node, runContext) => {
    const config = node.config;
    if (config.primitive !== "textToSpeech" || !config.languageModelId?.trim()) {
      return executeModelInferenceNode(node, runContext);
    }
    if (!runContext.speechSynthesizer) {
      throw new Error("Sprachausgabe über Sprachmodelle ist in dieser Umgebung nicht verfügbar.");
    }
    const text = runContext.templateExpressionResolver.resolveText(config.speechText ?? "");
    const speech = await runContext.speechSynthesizer.synthesize({
      teamId: runContext.teamId,
      languageModelId: config.languageModelId.trim(),
      text,
      voiceId: runContext.templateExpressionResolver.resolveText(config.voiceId ?? "").trim() || undefined,
    });
    const file = await runContext.teamFileStore.writeTeamFile({
      teamId: runContext.teamId,
      content: speech.bytes,
      fileName: `sprach-ausgabe.${speech.fileExtension}`,
      contentType: speech.contentType,
      targetFileId: null,
    });
    return ok(executedNode(node, {value: {type: "audio", value: fileReferenceFor(file)}}));
  },
};

/**
 * Sprache zu Text: Mit gewähltem Sprachmodell (`languageModelId`) transkribiert ein
 * verbundener Anbieter die Audiodatei aus `audioTemplate`; sonst läuft das ONNX-Modell.
 */
export const speechToTextNodeExecutor: NodeExecutor = {
  primitive: "speechToText",
  execute: async (node, runContext) => {
    const config = node.config;
    if (config.primitive !== "speechToText" || !config.languageModelId?.trim()) {
      return executeModelInferenceNode(node, runContext);
    }
    if (!runContext.speechTranscriber) {
      throw new Error("Transkription über Sprachmodelle ist in dieser Umgebung nicht verfügbar.");
    }
    const reference = runContext.templateExpressionResolver.resolveValue(config.audioTemplate ?? "");
    if (!isFileReference(reference)) {
      throw new Error("Für die Transkription wurde keine Audiodatei zugeordnet.");
    }
    const file = await runContext.fileContentReader.readTeamFileContent(runContext.teamId, reference.fileId, reference.versionId);
    const text = await runContext.speechTranscriber.transcribe({
      teamId: runContext.teamId,
      languageModelId: config.languageModelId.trim(),
      audio: {bytes: file.content, contentType: file.contentType, displayName: file.displayName},
    });
    return ok(executedNode(node, {value: {type: "string", value: text}}));
  },
};

function isFileReference(value: unknown): value is {fileId: string; versionId: string} {
  const candidate = value as {fileId?: unknown; versionId?: unknown} | null;
  return typeof candidate?.fileId === "string" && typeof candidate.versionId === "string";
}
