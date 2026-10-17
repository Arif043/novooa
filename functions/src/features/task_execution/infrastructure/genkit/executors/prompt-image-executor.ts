import {type TaskRunContext} from "../../../domain/executors/node-executor.js";
import {aiTurnMiddleware} from "../runner/node-attachment-genkit.js";
import {fileOutputFor} from "../../../domain/services/file-output-values.js";
import {type NodeOutputValue, type WorkflowNode} from "../runner/task-definition.js";
import {formatModelCallFinished, formatModelCallStarted} from "../runner/structured-logger.js";
import {imageDataFromDataUrl, imageExtensionFor} from "./image-data-url.js";
import {promptContentFor} from "./prompt-node-input.js";
import {type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";
import {type PromptModelCall} from "./prompt-model-call.js";
import {withTranslatedGenkitErrors} from "../../../../language_models/infrastructure/errors/genkit-error-translator.js";
import {ModelEmptyResponseError} from "../../../../language_models/infrastructure/errors/language-model-errors.js";

/** Bildmodelle verlangen die Bild-Modalität; Generierungsoptionen gelten hier nicht. */
export async function executeImagePrompt(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  const prompt = promptContentFor(input, call.workspace);
  const label = input.employee ? `Prompt / Bild (Mitarbeiter: ${input.employee.name})` : "Prompt / Bild";
  const startedAt = Date.now();
  call.logger.readableInfo(formatModelCallStarted({
    label, model: call.logContext, prompt: prompt.text, outputSchema: "dataUrl: Bild-Data-URL",
    mediaCount: input.mediaUrls.length,
  }));
  const response = await withTranslatedGenkitErrors(() => call.ai.generate({
    model: call.model, prompt: prompt.content,
    config: {responseModalities: ["IMAGE"]}, use: aiTurnMiddleware(call.workspace),
  }));
  const dataUrl = response.media?.url;
  if (!isImageDataUrl(dataUrl)) throw new ModelEmptyResponseError("Der Bild-Prompt lieferte keine Bild-Data-URL.");
  call.logger.readableInfo(formatModelCallFinished({
    label, durationMs: Date.now() - startedAt,
    text: `Bild generiert (${dataUrl.length} Zeichen)`,
  }));
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
