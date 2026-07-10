import {getApps, initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type DocumentReference,
  getFirestore,
} from "firebase-admin/firestore";
import {loadTaskDefinitionForTeam} from "../task-runner/task-definition-loader.js";
import {enqueueTaskRun} from "../task-runner/task-activity-logger.js";
import {errorDetails, logError, logInfo} from "../task-runner/structured-logger.js";
import {nextRunAfter, type ScheduleConfig} from "./schedule-next-run.js";

export async function runDueTaskTriggers(now = new Date()): Promise<void> {
  logInfo("task_trigger.started", {now: now.toISOString()});
  const dueTriggers = await getDatabase()
    .collectionGroup("taskTriggers")
    .where("enabled", "==", true)
    .where("nextRunAt", "<=", Timestamp.fromDate(now))
    .limit(50)
    .get();

  for (const trigger of dueTriggers.docs) {
    await runTrigger(trigger.ref, trigger.data(), now);
  }
}

async function runTrigger(
  reference: DocumentReference<DocumentData>,
  data: DocumentData,
  now: Date,
): Promise<void> {
  const teamId = reference.parent.parent?.id;
  if (!teamId) return;
  try {
    const config = scheduleConfigFrom(data.config);
    if (await shouldSkip(teamId, data)) {
      await advanceTrigger(reference, config, now);
      return;
    }
    const task = await loadTaskDefinitionForTeam(teamId, String(data.taskId));
    const run = await enqueueTaskRun({
      teamId,
      task,
      context: "",
      trigger: {id: reference.id, type: "schedule"},
    });
    await markTriggerRan(reference, config, now, run.runId);
  } catch (error) {
    logError("task_trigger.failed", {
      triggerId: reference.id,
      teamId,
      error: errorDetails(error),
    });
  }
}

async function shouldSkip(teamId: string, data: DocumentData): Promise<boolean> {
  const policy = String(data.policy?.ifRunning ?? "skipIfRunning");
  if (policy !== "skipIfRunning") return false;
  const active = await getDatabase()
    .collection("teams")
    .doc(teamId)
    .collection("taskRuns")
    .where("taskId", "==", String(data.taskId))
    .where("status", "in", ["queued", "running", "waitingForApproval"])
    .limit(1)
    .get();
  return !active.empty;
}

async function markTriggerRan(
  reference: DocumentReference<DocumentData>,
  config: ScheduleConfig,
  now: Date,
  runId: string,
) {
  const nextRunAt = nextRunAfter(config, new Date(now.getTime() + 1000));
  await reference.set({
    enabled: nextRunAt !== null,
    lastRunAt: Timestamp.fromDate(now),
    lastRunId: runId,
    nextRunAt: nextRunAt ? Timestamp.fromDate(nextRunAt) : null,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

async function advanceTrigger(
  reference: DocumentReference<DocumentData>,
  config: ScheduleConfig,
  now: Date,
) {
  const nextRunAt = nextRunAfter(config, new Date(now.getTime() + 1000));
  await reference.set({
    enabled: nextRunAt !== null,
    nextRunAt: nextRunAt ? Timestamp.fromDate(nextRunAt) : null,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

function scheduleConfigFrom(value: unknown): ScheduleConfig {
  const data = isRecord(value) ? value : {};
  return {
    kind: scheduleKindFrom(data.kind),
    timezone: String(data.timezone ?? "Europe/Berlin"),
    runAt: data.runAt instanceof Timestamp ? data.runAt : undefined,
    timeOfDay: typeof data.timeOfDay === "string" ? data.timeOfDay : undefined,
    weekdays: Array.isArray(data.weekdays) ? data.weekdays.map(Number) : [],
  };
}

function scheduleKindFrom(value: unknown): ScheduleConfig["kind"] {
  if (value === "once" || value === "daily" || value === "weekly") return value;
  return "daily";
}

function getDatabase() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
