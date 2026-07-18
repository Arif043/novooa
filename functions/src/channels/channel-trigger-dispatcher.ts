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
import {
  type ChannelMessageEvent,
  messageFromEvent,
  recipientFromEvent,
  senderFromEvent,
} from "./channel-message-event.js";

export async function dispatchChannelMessageTriggers(input: {
  teamId: string;
  channelId: string;
  event: ChannelMessageEvent;
}): Promise<void> {
  const triggers = await getFirestore()
    .collection("teams")
    .doc(input.teamId)
    .collection("taskTriggers")
    .where("enabled", "==", true)
    .get();
  logInfo("channel_message.dispatch_started", {
    teamId: input.teamId,
    channelId: input.channelId,
    eventType: input.event.type,
    triggerCount: triggers.size,
  });
  for (const trigger of triggers.docs) {
    const decision = matchDecision(trigger, input);
    logInfo("channel_message.trigger_checked", {
      teamId: input.teamId,
      triggerId: trigger.id,
      matched: decision.matched,
      reason: decision.reason,
      triggerType: trigger.get("type"),
      source: trigger.get("eventConfig.source"),
      channelId: trigger.get("eventConfig.channelId") ?? null,
      filterLength: String(trigger.get("eventConfig.filter") ?? "").trim().length,
    });
    if (decision.matched) {
      await enqueueTriggerRun(input.teamId, trigger, input);
    }
  }
}

async function enqueueTriggerRun(
  teamId: string,
  trigger: QueryDocumentSnapshot<DocumentData>,
  input: {
    channelId: string;
    event: ChannelMessageEvent;
  },
): Promise<void> {
  try {
    const task = await loadTaskDefinitionForTeam(teamId, String(trigger.get("taskId")));
    const run = await enqueueTaskRun({
      teamId,
      task,
      context: contextFrom(input.event),
      input: {
        event: input.event,
      },
      trigger: {id: trigger.id, type: "event"},
    });
    await trigger.ref.set({
      lastRunAt: FieldValue.serverTimestamp(),
      lastRunId: run.runId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    logInfo("channel_message.trigger_enqueued", {teamId, triggerId: trigger.id});
  } catch (error) {
    logError("channel_message.trigger_failed", {
      teamId,
      triggerId: trigger.id,
      error: errorDetails(error),
    });
  }
}

function matchDecision(
  trigger: QueryDocumentSnapshot<DocumentData>,
  input: {
    channelId: string;
    event: ChannelMessageEvent;
  },
): {matched: boolean; reason: string} {
  if (trigger.get("type") !== "event") return noMatch("not_event_trigger");
  if (trigger.get("eventConfig.source") !== input.event.type) {
    return noMatch("event_type_mismatch");
  }
  if (!matchesChannel(trigger, input.channelId)) return noMatch("channel_mismatch");
  if (!matchesFilter(trigger, input.event)) return noMatch("filter_mismatch");
  return {matched: true, reason: "matched"};
}

function matchesChannel(
  trigger: QueryDocumentSnapshot<DocumentData>,
  channelId: string,
): boolean {
  const configuredChannelId = String(trigger.get("eventConfig.channelId") ?? "");
  return configuredChannelId.trim().length === 0 ||
    configuredChannelId === channelId;
}

function matchesFilter(
  trigger: QueryDocumentSnapshot<DocumentData>,
  event: ChannelMessageEvent,
): boolean {
  const filter = String(trigger.get("eventConfig.filter") ?? "").trim();
  if (filter.length === 0) return true;
  const haystack = searchableTextFrom(event).toLowerCase();
  return haystack.includes(filter.toLowerCase());
}

function contextFrom(event: ChannelMessageEvent): string {
  if (event.type === "emailReceived") {
    return [
      "E-Mail empfangen",
      `Von: ${event.senderEmail}`,
      `Betreff: ${event.subject}`,
      "",
      event.message,
    ].join("\n");
  }
  return [
    `${eventLabel(event)} empfangen`,
    `Von: ${event.senderPhoneNumber}`,
    "",
    event.message,
  ].join("\n");
}

function searchableTextFrom(event: ChannelMessageEvent): string {
  if (event.type === "emailReceived") {
    return [
      event.senderEmail,
      event.recipientEmail,
      event.subject,
      event.message,
    ].join(" ");
  }
  return [
    senderFromEvent(event),
    recipientFromEvent(event),
    messageFromEvent(event),
  ].join(" ");
}

function eventLabel(event: ChannelMessageEvent): string {
  if (event.type === "smsMessageReceived") return "SMS";
  return "WhatsApp-Nachricht";
}

function noMatch(reason: string): {matched: false; reason: string} {
  return {matched: false, reason};
}

if (getApps().length === 0) initializeApp();
