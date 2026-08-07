import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import {type ScheduleConfig} from "../../domain/usecases/schedule-next-run.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {
  type DueScheduleTrigger,
  type EventTaskTrigger,
  type TaskTriggerStore,
} from "../../domain/repositories/task-trigger-store.js";

export class FirestoreTaskTriggerStore implements TaskTriggerStore {
  async listDueScheduleTriggers(now: Date, limit: number) {
    const snapshot = await getDatabase().collectionGroup("taskTriggers")
      .where("enabled", "==", true)
      .where("nextRunAt", "<=", Timestamp.fromDate(now))
      .limit(limit)
      .get();
    return snapshot.docs.flatMap(scheduleTriggerFrom);
  }

  async hasActiveRun(teamId: string, taskId: string): Promise<boolean> {
    const snapshot = await getDatabase().collection("teams").doc(teamId)
      .collection("taskRuns")
      .where("taskId", "==", taskId)
      .where("status", "in", ["queued", "running", "waitingForApproval"])
      .limit(1)
      .get();
    return !snapshot.empty;
  }

  async advanceScheduleTrigger(trigger: DueScheduleTrigger, nextRunAt: Date | null) {
    await triggerReference(trigger).set(scheduleAdvanceDocument(nextRunAt), {
      merge: true,
    });
  }

  async markScheduleTriggerRan(
    trigger: DueScheduleTrigger,
    now: Date,
    nextRunAt: Date | null,
    runId: string,
  ) {
    await triggerReference(trigger).set(scheduleRanDocument(now, nextRunAt, runId), {
      merge: true,
    });
  }

  async listEnabledEventTriggers(teamId: string): Promise<EventTaskTrigger[]> {
    const snapshot = await getDatabase().collection("teams").doc(teamId)
      .collection("taskTriggers")
      .where("enabled", "==", true)
      .get();
    return snapshot.docs.map((document) => eventTriggerFrom(teamId, document));
  }

  async markEventTriggerRan(trigger: EventTaskTrigger, runId: string) {
    await triggerReference(trigger).set({
      lastRunAt: FieldValue.serverTimestamp(),
      lastRunId: runId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
}

function scheduleTriggerFrom(
  document: QueryDocumentSnapshot<DocumentData>,
): DueScheduleTrigger[] {
  const teamId = document.ref.parent.parent?.id;
  if (!teamId) return [];
  return [triggerFromDocument(teamId, document)];
}

function triggerFromDocument(
  teamId: string,
  document: QueryDocumentSnapshot<DocumentData>,
): DueScheduleTrigger {
  const data = document.data();
  return {
    id: document.id,
    teamId,
    taskId: String(data.taskId ?? ""),
    config: scheduleConfigFrom(data.config),
    policy: {ifRunning: String(data.policy?.ifRunning ?? "skipIfRunning")},
  };
}

function eventTriggerFrom(
  teamId: string,
  document: QueryDocumentSnapshot<DocumentData>,
): EventTaskTrigger {
  return {
    id: document.id,
    teamId,
    taskId: String(document.get("taskId") ?? ""),
    type: String(document.get("type") ?? ""),
    eventConfig: {
      source: String(document.get("eventConfig.source") ?? ""),
      channelId: String(document.get("eventConfig.channelId") ?? ""),
      connectorId: String(document.get("eventConfig.connectorId") ?? ""),
      filter: String(document.get("eventConfig.filter") ?? ""),
    },
  };
}

function scheduleAdvanceDocument(nextRunAt: Date | null) {
  return {
    enabled: nextRunAt !== null,
    nextRunAt: timestampOrNull(nextRunAt),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function scheduleRanDocument(now: Date, nextRunAt: Date | null, runId: string) {
  return {
    enabled: nextRunAt !== null,
    lastRunAt: Timestamp.fromDate(now),
    lastRunId: runId,
    nextRunAt: timestampOrNull(nextRunAt),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function scheduleConfigFrom(value: unknown): ScheduleConfig {
  const data = isRecord(value) ? value : {};
  return {
    kind: scheduleKindFrom(data.kind),
    timezone: String(data.timezone ?? "Europe/Berlin"),
    runAt: data.runAt instanceof Timestamp ? data.runAt.toDate() : undefined,
    timeOfDay: stringOrUndefined(data.timeOfDay),
    weekdays: Array.isArray(data.weekdays) ? data.weekdays.map(Number) : [],
    slots: Array.isArray(data.slots) ? data.slots.map(slotFrom) : [],
  };
}

function slotFrom(value: unknown) {
  const data = isRecord(value) ? value : {};
  return {weekday: Number(data.weekday ?? 0), timeOfDay: String(data.timeOfDay ?? "")};
}

function scheduleKindFrom(value: unknown): ScheduleConfig["kind"] {
  if (value === "once" || value === "daily" || value === "weekly") return value;
  return "daily";
}

function triggerReference(trigger: {teamId: string; id: string}) {
  return getDatabase().collection("teams").doc(trigger.teamId)
    .collection("taskTriggers").doc(trigger.id);
}

function timestampOrNull(value: Date | null) {
  return value ? Timestamp.fromDate(value) : null;
}

function stringOrUndefined(value: unknown) {
  return typeof value === "string" ? value : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
