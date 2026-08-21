import {type GenkitBeta} from "genkit/beta";
import {imageModel, imageModelLogContext} from "../runner/ai-models.js";
import {type TaskRunContext} from "../runner/node-executor.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {aiTurnMiddleware} from "../runner/node-attachment-genkit.js";
import {fileOutputFor} from "../runner/file-output-values.js";
import {type NodeOutputValue, type WorkflowNode} from "../runner/task-definition.js";
import {formatModelCallFinished, formatModelCallStarted, logReadableInfo} from "../runner/structured-logger.js";
import {imageDataFromDataUrl, imageExtensionFor} from "./image-data-url.js";
import {promptContentFor} from "./prompt-node-input.js";
import {type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";

export async function executeImagePrompt(
  ai: GenkitBeta,
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  const prompt = promptContentFor(input, workspace);
  const label = input.employee ? `Prompt / Bild (Mitarbeiter: ${input.employee.name})` : "Prompt / Bild";
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label, model: imageModelLogContext(), prompt: prompt.text,
    outputSchema: "dataUrl: Bild-Data-URL",
  }));
  const response = await ai.generate({
    model: imageModel(), prompt: prompt.content,
    config: {responseModalities: ["IMAGE"]}, use: aiTurnMiddleware(workspace),
  });
  const dataUrl = response.media?.url;
  if (!isImageDataUrl(dataUrl)) throw new Error("Der Bild-Prompt lieferte keine Bild-Data-URL.");
  logReadableInfo(formatModelCallFinished({
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
