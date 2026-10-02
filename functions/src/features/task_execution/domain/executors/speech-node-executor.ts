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
    return executedNode(node, {value: {type: "audio", value: fileReferenceFor(file)}});
  },
};

export const speechToTextNodeExecutor: NodeExecutor = {
  primitive: "speechToText",
  execute: executeModelInferenceNode,
};
