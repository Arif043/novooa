import {type GenkitBeta} from "genkit/beta";
import {type NodeExecutor, executedNode} from "../runner/node-executor.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {executeImagePrompt, persistedImageOutputsFor} from "./prompt-image-executor.js";
import {promptInputFor} from "./prompt-node-input.js";
import {executeDecisionPrompt, executeStructuredPrompt, executeTextPrompt} from "./prompt-text-executor.js";
import {type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";

export type {PromptNodeInput, PromptNodeOutput, PromptNodeOutputType} from "./prompt-node-types.js";

export const promptNodeExecutor: NodeExecutor = {
  primitive: "prompt",
  async execute(input, runContext) {
    const promptInput = await promptInputFor(input, runContext);
    const output = await executePromptNode(input.ai, promptInput, input.attachmentWorkspace);
    const outputs = promptInput.outputType === "image"
      ? await persistedImageOutputsFor(output, input.node, runContext)
      : output.outputs;
    return executedNode(input.node, outputs);
  },
};

export async function executePromptNode(
  ai: GenkitBeta,
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
): Promise<PromptNodeOutput> {
  if (input.outputType === "image") return executeImagePrompt(ai, input, workspace);
  if (input.outputType === "decision") return executeDecisionPrompt(ai, input, workspace);
  if (input.outputType === "structured") return executeStructuredPrompt(ai, input, workspace);
  return executeTextPrompt(ai, input, workspace);
}
