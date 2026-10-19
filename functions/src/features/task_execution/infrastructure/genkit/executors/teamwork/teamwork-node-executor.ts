import {err, ok, ResultAsync} from "neverthrow";
import {type GenkitBeta} from "genkit/beta";
import {NodeFailure} from "../../../../domain/entities/node-failure.js";
import {nodeFailures} from "../../../../domain/entities/node-failures.js";
import {type TeamworkNodeConfig} from "../../../../domain/entities/teamwork-config.js";
import {type NodeOutputValue} from "../../../../domain/entities/workflow-value.js";
import {executedNode, type NodeExecutor, type TaskRunContext} from "../../../../domain/executors/node-executor.js";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {generationOptionsFrom} from "../../../../../language_models/domain/entities/generation-options.js";
import {type LanguageModelDefaultsStore} from "../../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {languageModelFailureFrom} from "../../../../../language_models/infrastructure/errors/language-model-failure-mapper.js";
import {type GenkitLanguageModelResolver} from "../../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {attachmentInstructions} from "../../runner/node-attachment-genkit.js";
import {type NodeAttachmentWorkspace} from "../../runner/node-attachment-workspace.js";
import {type TeamWorkspace} from "../../runner/teamwork-workspace.js";
import {type TeamworkExecutionRequest} from "../../../../domain/entities/teamwork-execution.js";
import {type WorkflowNode} from "../../runner/task-definition.js";
import {resolvedInstruction} from "../prompt-node-input.js";
import {fieldOutputsFor} from "../structured-output-schema.js";
import {GenkitTeamworkExecutor} from "./genkit-teamwork-executor.js";
import {persistedResultFile} from "./teamwork-file-outputs.js";
import {teamworkImageInstructions, writeTeamworkImages} from "./teamwork-images.js";
import {TeamworkTranscript} from "./teamwork-transcript.js";
import {namedOutputFields} from "./teamwork-output-schema.js";

export type TeamworkNodeExecutorDependencies = {
  ai: GenkitBeta;
  logger: ApplicationLogger;
  workspace?: NodeAttachmentWorkspace;
  languageModelResolver?: GenkitLanguageModelResolver;
  defaultsStore?: LanguageModelDefaultsStore;
};

/** Der Baustein „Teamarbeit“: prüft die Konfiguration, lässt das Team arbeiten und macht aus dem Ergebnis Workflow-Werte. */
export function createTeamworkNodeExecutor(dependencies: TeamworkNodeExecutorDependencies): NodeExecutor {
  return {
    primitive: "teamwork",
    async execute(node, runContext) {
      const config = teamworkConfigOf(node);
      const fields = namedOutputFields(config.outputFields);
      if (config.members.length === 0) return err(nodeFailures.settingMissing("teamMembers"));
      if (fields.length === 0) return err(nodeFailures.settingMissing("resultFields"));
      const workspace = teamWorkspaceOf(dependencies.workspace);
      const transcript = new TeamworkTranscript(dependencies.logger);
      const executor = new GenkitTeamworkExecutor({...dependencies, workspace, transcript});
      const request = await requestFor({...config, outputFields: fields}, node, runContext, workspace);
      const outputsOrFailure = await executor.execute(request).andThen(({fields: values}) => ResultAsync.fromPromise(
        outputsFor(fields, values, workspace.team.sharedDirectory, runContext), languageModelFailureFrom,
      ));
      const conversation = transcript.entries();
      if (outputsOrFailure.isErr()) return err(NodeFailure.of(outputsOrFailure.error).withConversation(conversation));
      return ok(executedNode(node, outputsOrFailure.value, {conversation}));
    },
  };
}

async function requestFor(
  config: TeamworkNodeConfig, node: WorkflowNode, runContext: TaskRunContext, workspace: NodeAttachmentWorkspace,
): Promise<TeamworkExecutionRequest> {
  const instruction = await resolvedInstruction(config.instruction.trim() || node.title, runContext);
  const imagePaths = await writeTeamworkImages(workspace.rootDirectory, instruction.mediaUrls);
  return {
    teamId: runContext.teamId,
    languageModelId: config.languageModelId,
    instruction: [instruction.text, attachmentInstructions(workspace), teamworkImageInstructions(imagePaths)]
      .filter(Boolean).join("\n\n"),
    generationOptions: generationOptionsFrom(config.generationOptions),
    outputFields: config.outputFields,
    review: config.review,
    mediaUrls: instruction.mediaUrls,
  };
}

function teamWorkspaceOf(workspace?: NodeAttachmentWorkspace): NodeAttachmentWorkspace & {team: TeamWorkspace} {
  if (!workspace?.team) throw new Error("Der Arbeitsordner der Teamarbeit fehlt.");
  return {...workspace, team: workspace.team};
}

async function outputsFor(
  fields: TeamworkNodeConfig["outputFields"], values: Record<string, unknown>,
  sharedDirectory: string, runContext: TaskRunContext,
): Promise<Record<string, NodeOutputValue>> {
  const outputs = fieldOutputsFor(values, fields.flatMap((field) => (field.type === "file" ? [] : [field])));
  const target = {teamId: runContext.teamId, sharedDirectory, teamFileStore: runContext.teamFileStore};
  for (const field of fields) {
    if (field.type === "file") outputs[field.name.trim()] = await persistedResultFile(field, values[field.name.trim()], target);
  }
  return outputs;
}

function teamworkConfigOf(node: WorkflowNode): TeamworkNodeConfig {
  if (node.config.primitive !== "teamwork") throw new Error("Teamarbeit-Konfiguration fehlt.");
  return node.config;
}
