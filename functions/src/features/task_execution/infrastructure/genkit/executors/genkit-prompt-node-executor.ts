import {err, ok} from "neverthrow";
import {type GenkitBeta} from "genkit/beta";
import {type NodeExecutor, executedNode} from "../../../domain/executors/node-executor.js";
import {NodeFailure} from "../../../domain/entities/node-failure.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {GenkitPromptExecutor} from "./genkit-prompt-executor.js";
import {persistedImageOutputsFor} from "./prompt-image-executor.js";
import {promptInputFor} from "./prompt-node-input.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {FirebaseApplicationLogger} from "../../../../../shared/logging/firebase-application-logger.js";

/** Der Baustein „Prompt“: baut den Request, ruft den Port und gibt eine Failure als Wert an den Runner. */
export function createGenkitPromptNodeExecutor(
  ai: GenkitBeta,
  workspace?: NodeAttachmentWorkspace,
  languageModelResolver?: GenkitLanguageModelResolver,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
  defaultsStore?: LanguageModelDefaultsStore,
): NodeExecutor {
  const promptExecutor = new GenkitPromptExecutor({ai, workspace, languageModelResolver, defaultsStore, logger});
  return {
    primitive: "prompt",
    async execute(node, runContext) {
      const request = await promptInputFor(node, runContext, workspace?.employee);
      const answerOrFailure = await promptExecutor.execute(request);
      if (answerOrFailure.isErr()) return err(NodeFailure.of(answerOrFailure.error));
      const answer = answerOrFailure.value;
      const outputs = request.outputType === "image"
        ? await persistedImageOutputsFor(answer, node, runContext)
        : answer.outputs;
      return ok(executedNode(node, outputs));
    },
  };
}
