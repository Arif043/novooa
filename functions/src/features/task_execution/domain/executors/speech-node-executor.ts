import {type NodeExecutor} from "./node-executor.js";
import {executeModelInferenceNode} from "./model-inference-node-executor.js";

/** Spezialisierte Oberfläche ueber die allgemeine, manifestgesteuerte Inferenz. */
export const textToSpeechNodeExecutor: NodeExecutor = {
  primitive: "textToSpeech",
  execute: executeModelInferenceNode,
};

export const speechToTextNodeExecutor: NodeExecutor = {
  primitive: "speechToText",
  execute: executeModelInferenceNode,
};
