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
  if (interaction.kind === "dialogInput") {
    return dialogInputOutputs(interaction, formValues);
  }
  return mediaInputOutputs(interaction, formValues, teamId, teamFileStore);
}

function waitingResultFor(resumeState: TaskResumeState) {
  return resumeState.nodeResults.find(
    (result) => result.nodeId === resumeState.waitingNodeId,
  );
}

function textOutput(output: string): Record<string, NodeOutputValue> {
  return {text: {type: "string", value: output}};
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

function dialogInputOutputs(
  interaction: Extract<TaskRunInteraction, {kind: "dialogInput"}>,
  formValues: Record<string, unknown>,
): Record<string, NodeOutputValue> {
  const values = validateDialogInputValues(interaction, formValues);
  const outputs = Object.entries(values).reduce<Record<string, NodeOutputValue>>(
    (current, [name, value]) => {
      current[name] = outputFor(value);
      return current;
    },
    {},
  );
  return {...textOutput(JSON.stringify(values)), ...outputs};
}

async function mediaInputOutputs(
  interaction: Extract<TaskRunInteraction, {kind: "mediaInput"}>,
  formValues: Record<string, unknown>,
  teamId: string,
  teamFileStore: TeamFileStore,
): Promise<Record<string, NodeOutputValue>> {
  const fileId = formValues.fileId;
  if (typeof fileId !== "string" || fileId.trim().length === 0) {
    throw new Error("Bitte wähle ein Bild aus.");
  }
  const file = await teamFileStore.loadTeamFile(teamId, fileId);
  if (!file.contentType.startsWith("image/")) {
    throw new Error("Die ausgewählte Datei ist kein Bild.");
  }
  return mediaFileOutputs(file);
}

function mediaFileOutputs(
  file: Awaited<ReturnType<TeamFileStore["loadTeamFile"]>>,
): Record<string, NodeOutputValue> {
  const value = {
    fileId: file.fileId,
    versionId: file.versionId,
    storagePath: file.storagePath,
    displayName: file.displayName,
    contentType: file.contentType,
    sizeBytes: file.sizeBytes,
  };
  return {
    text: {type: "string", value: JSON.stringify(value)},
    fileId: {type: "string", value: file.fileId},
    versionId: {type: "string", value: file.versionId},
    storagePath: {type: "string", value: file.storagePath},
    displayName: {type: "string", value: file.displayName},
    contentType: {type: "string", value: file.contentType},
    sizeBytes: {type: "number", value: file.sizeBytes},
  };
}

function outputFor(value: string | number | boolean): NodeOutputValue {
  if (typeof value === "number") return {type: "number", value};
  if (typeof value === "boolean") return {type: "boolean", value};
  return {type: "string", value};
}
