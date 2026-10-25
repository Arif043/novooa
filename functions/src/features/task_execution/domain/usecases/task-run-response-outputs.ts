import {
  validateDialogInputValues,
} from "../entities/dialog-input.js";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type TaskResumeState,
} from "../entities/task.js";
import {type TaskRunInteraction} from "../entities/task-run-interaction.js";
import {type TeamFileStore} from "../../../files/domain/repositories/team-file-store.js";
import {mediaReferenceFor, primitiveNodeOutputValue} from "../entities/workflow-value.js";

export async function responseOutputsForTaskRun(
  resumeState: TaskResumeState,
  output: string,
  formValues: Record<string, unknown>,
  teamId: string,
  teamFileStore: TeamFileStore,
): Promise<Record<string, NodeOutputValue>> {
  const waitingResult = waitingResultFor(resumeState);
  const interaction = interactionFor(waitingResult);
  if (interaction.kind === "approval") return textOutput(output);
  return dialogInputOutputs(interaction, formValues, {teamId, teamFileStore});
}

function waitingResultFor(resumeState: TaskResumeState) {
  return resumeState.nodeResults.find(
    (result) => result.nodeId === resumeState.waitingNodeId,
  );
}

function textOutput(output: string): Record<string, NodeOutputValue> {
  return {value: {type: "string" as const, value: output}};
}

function interactionFor(
  result: NodeExecutionResult | undefined,
): TaskRunInteraction {
  if (result?.interaction !== undefined) return result.interaction;
  if (result?.dialogInput !== undefined) {
    return {kind: "dialogInput", ...result.dialogInput};
  }
  return {kind: "approval", instruction: "Prüfe das Ergebnis und gib es frei."};
}

type FileLookup = {teamId: string; teamFileStore: TeamFileStore};

/** Jedes Feld wird ein eigener Wert; Bildfelder werden dabei zur Referenz auf die Team-Datei. */
async function dialogInputOutputs(
  interaction: Extract<TaskRunInteraction, {kind: "dialogInput"}>,
  formValues: Record<string, unknown>,
  files: FileLookup,
): Promise<Record<string, NodeOutputValue>> {
  const values = validateDialogInputValues(interaction, formValues);
  const outputs: Record<string, NodeOutputValue> = {};
  const json: Record<string, unknown> = {};
  for (const field of interaction.fields) {
    const name = field.name.trim();
    const output = field.type === "image"
      ? await imageOutput(String(values[name]), files)
      : primitiveNodeOutputValue(values[name]);
    outputs[name] = output;
    json[name] = output.value;
  }
  return {value: {type: "json", value: json}, ...outputs};
}

async function imageOutput(fileId: string, {teamId, teamFileStore}: FileLookup): Promise<NodeOutputValue> {
  const file = await teamFileStore.loadTeamFile(teamId, fileId);
  if (!file.contentType.startsWith("image/")) {
    throw new Error("Die ausgewählte Datei ist kein Bild.");
  }
  const {fileId: id, versionId, displayName, contentType, sizeBytes} = file;
  return {type: "media", value: mediaReferenceFor({fileId: id, versionId, displayName, contentType, sizeBytes})};
}
