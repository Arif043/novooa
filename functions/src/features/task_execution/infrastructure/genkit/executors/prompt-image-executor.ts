import {type TaskRunContext} from "../../../domain/executors/node-executor.js";
import {fileOutputFor} from "../../../domain/services/file-output-values.js";
import {type NodeOutputValue, type WorkflowNode} from "../runner/task-definition.js";
import {imageDataFromDataUrl, imageExtensionFor} from "./image-data-url.js";
import {type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";
import {bindingFor, type PromptModelCall} from "./prompt-model-call.js";
import {promptNodePrompt} from "./prompt-node-prompt.js";
import {promptNodeLabel} from "./prompt-text-executor.js";
import {ModelEmptyResponseError} from "../../../../language_models/infrastructure/errors/language-model-errors.js";

/** Bildmodelle verlangen die Bild-Modalität; die setzt der Gateway, Generierungsoptionen gelten hier nicht. */
export async function executeImagePrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  const response = await call.gateway.generate({
    binding: bindingFor(call), prompt: promptNodePrompt(input, call.workspace),
    label: promptNodeLabel(input, "Bild"), output: {kind: "image"},
  });
  const dataUrl = response.mediaUrl;
  if (!isImageDataUrl(dataUrl)) throw new ModelEmptyResponseError("Der Bild-Prompt lieferte keine Bild-Data-URL.");
  return {answer: dataUrl, outputs: {dataUrl: {type: "string", value: dataUrl}}};
}

export async function persistedImageOutputsFor(
  output: PromptNodeOutput,
  node: WorkflowNode,
  runContext: TaskRunContext,
): Promise<Record<string, NodeOutputValue>> {
  const image = imageDataFromDataUrl(output.answer);
  const file = await runContext.teamFileStore.writeTeamFile({
    teamId: runContext.teamId, content: image.bytes, contentType: image.contentType,
    fileName: `generiertes-bild-${node.id}.${imageExtensionFor(image.contentType)}`,
    targetFileId: null,
  });
  return {value: fileOutputFor(file)};
}

function isImageDataUrl(value: string | undefined): value is string {
  return value?.startsWith("data:image/") ?? false;
}
