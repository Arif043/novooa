import {getApps, initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  type DocumentData,
  type QueryDocumentSnapshot,
  getFirestore,
} from "firebase-admin/firestore";
import {enqueueTaskRun} from "../task-runner/task-activity-logger.js";
import {loadTaskDefinitionForTeam} from "../task-runner/task-definition-loader.js";
import {errorDetails, logError, logInfo} from "../task-runner/structured-logger.js";
import type {TwilioMessageEvent} from "./twilio-message-event.js";

export async function dispatchTwilioMessageTriggers(input: {
  teamId: string;
  event: TwilioMessageEvent;
}): Promise<void> {
  if (input.event.channel !== "whatsapp") return;
  const triggers = await getFirestore()
    .collection("teams")
    .doc(input.teamId)
    .collection("taskTriggers")
    .where("enabled", "==", true)
    .get();
  for (const trigger of triggers.docs) {
    if (isWhatsappEventTrigger(trigger) && matchesFilter(trigger, input.event)) {
      await enqueueTriggerRun(input.teamId, trigger, input.event);
    }
  }
}

async function enqueueTriggerRun(
  teamId: string,
  trigger: QueryDocumentSnapshot<DocumentData>,
  event: TwilioMessageEvent,
): Promise<void> {
  try {
    const task = await loadTaskDefinitionForTeam(teamId, String(trigger.get("taskId")));
    const run = await enqueueTaskRun({
      teamId,
      task,
      context: contextFrom(event),
      trigger: {id: trigger.id, type: "event"},
    });
    await trigger.ref.set({
      lastRunAt: FieldValue.serverTimestamp(),
      lastRunId: run.runId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    logInfo("twilio_message.trigger_enqueued", {teamId, triggerId: trigger.id});
  } catch (error) {
    logError("twilio_message.trigger_failed", {
      teamId,
      triggerId: trigger.id,
      error: errorDetails(error),
    });
  }
}

function isWhatsappEventTrigger(
  trigger: QueryDocumentSnapshot<DocumentData>,
): boolean {
  return trigger.get("type") === "event" &&
    trigger.get("eventConfig.source") === "whatsappMessageReceived";
}

function matchesFilter(
  trigger: QueryDocumentSnapshot<DocumentData>,
  event: TwilioMessageEvent,
): boolean {
  const filter = String(trigger.get("eventConfig.filter") ?? "").trim();
  if (filter.length === 0) return true;
  const haystack = `${event.from} ${event.to} ${event.body}`.toLowerCase();
  return haystack.includes(filter.toLowerCase());
}

function contextFrom(event: TwilioMessageEvent): string {
  return [
    "WhatsApp-Nachricht empfangen",
    `Von: ${event.from}`,
    `An: ${event.to}`,
    "",
    event.body,
  ].join("\n");
}

if (getApps().length === 0) initializeApp();
