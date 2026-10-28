import {type TeamFileStore} from "../../../files/domain/repositories/team-file-store.js";
import {type WorkflowPrimitive} from "../entities/task.js";
import {type TaskRunServices} from "../executors/node-executor.js";
import {EffectRecordingDocumentStore} from "./effect-recording-document-store.js";
import {
  EffectRecordingHttpClient,
  EffectRecordingMessageSender,
  EffectRecordingNotificationSender,
  EffectRecordingTeamFileStore,
} from "./effect-recording-ports.js";
import {type RunEffectRecorder} from "./run-effect-recorder.js";

type RecordedPorts = Pick<TaskRunServices, "messageSender" | "documentStore" | "teamNotificationSender" | "outboundHttpClient">;

/**
 * HTTP-Aufrufe sind nur beim HTTP-Baustein selbst eine Folge; Plugins nutzen denselben Client,
 * melden aber ihre fachliche Aktion (`externalAction`) statt jeder einzelnen Anfrage.
 */
export function recordsHttpEffects(primitive: WorkflowPrimitive): boolean {
  return primitive === "httpRequest";
}

/** Die nach außen wirkenden Ports eines Bausteins, jeweils mit seinem Recorder umhüllt. */
export function effectRecordingPorts<Ports extends RecordedPorts>(
  ports: Ports,
  teamFileStore: TeamFileStore,
  effects: RunEffectRecorder,
  options: {recordHttp: boolean},
): Ports & {teamFileStore: TeamFileStore} {
  const {outboundHttpClient} = ports;
  return {
    ...ports,
    messageSender: new EffectRecordingMessageSender(ports.messageSender, effects),
    documentStore: new EffectRecordingDocumentStore(ports.documentStore, effects),
    teamNotificationSender: new EffectRecordingNotificationSender(ports.teamNotificationSender, effects),
    outboundHttpClient: outboundHttpClient && options.recordHttp
      ? new EffectRecordingHttpClient(outboundHttpClient, effects)
      : outboundHttpClient,
    teamFileStore: new EffectRecordingTeamFileStore(teamFileStore, effects),
  };
}
