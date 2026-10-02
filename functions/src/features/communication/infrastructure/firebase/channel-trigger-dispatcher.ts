import {triggerChainInputKey} from "../../../scheduling/domain/entities/trigger-chain.js";
import {messageTargetMatches} from "../../../scheduling/domain/usecases/event-trigger-matching.js";
import {type TaskRunStore} from "../../../task_execution/domain/repositories/task-run-store.js";
import {type TaskRunDispatcher} from
  "../../../task_execution/domain/repositories/task-run-dispatcher.js";
import {type TaskStore} from "../../../task_execution/domain/repositories/task-store.js";
import {FirebaseTaskRunDispatcher} from
  "../../../task_execution/infrastructure/firebase/firebase-task-run-dispatcher.js";
import {
  createFirebaseTaskRunStore,
} from "../../../task_execution/infrastructure/firebase/firebase-task-run-store-factory.js";
import {
  createFirebaseTaskRunApprovalNotificationStore,
} from "../../../notifications/infrastructure/firebase/firebase-task-run-approval-notification-store-factory.js";
import {FirestoreTaskStore} from "../../../task_execution/infrastructure/firebase/firestore-task-store.js";
import {errorDetails, logError, logInfo} from "../../../../shared/logging/logger.js";
import {FirestoreTaskTriggerStore} from "../../../scheduling/infrastructure/firebase/firestore-task-trigger-store.js";
import {
  type EventTaskTrigger,
  type TaskTriggerStore,
} from "../../../scheduling/domain/repositories/task-trigger-store.js";
import {
  type ChannelMessageEvent,
  messageFromEvent,
  recipientFromEvent,
  senderFromEvent,
} from "../../domain/entities/channel-message-event.js";

type ChannelTriggerDispatcherStores = {
  triggerStore: TaskTriggerStore;
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
  taskRunDispatcher: TaskRunDispatcher;
};

const defaultStores: ChannelTriggerDispatcherStores = {
  triggerStore: new FirestoreTaskTriggerStore(),
  taskStore: new FirestoreTaskStore(),
  taskRunStore: createFirebaseTaskRunStore(
    createFirebaseTaskRunApprovalNotificationStore(),
  ),
  taskRunDispatcher: new FirebaseTaskRunDispatcher(),
};

export async function dispatchChannelMessageTriggers(input: {
  teamId: string;
  channelId: string;
  event: ChannelMessageEvent;
}, stores: ChannelTriggerDispatcherStores = defaultStores): Promise<void> {
  const triggers = await stores.triggerStore.listEnabledEventTriggers(input.teamId);
  logInfo("channel_message.dispatch_started", {
    teamId: input.teamId,
    channelId: input.channelId,
    eventType: input.event.type,
    triggerCount: triggers.length,
  });
  for (const trigger of triggers) {
    const decision = matchDecision(trigger, input);
    logInfo("channel_message.trigger_checked", {
      teamId: input.teamId,
      triggerId: trigger.id,
      matched: decision.matched,
      reason: decision.reason,
      triggerType: trigger.type,
      source: trigger.eventConfig.source,
      target: trigger.eventConfig.target,
      filterLength: trigger.eventConfig.filter.trim().length,
    });
    if (decision.matched) {
      await enqueueTriggerRun(trigger, input, stores);
    }
  }
}

async function enqueueTriggerRun(
  trigger: EventTaskTrigger,
  input: {
    channelId: string;
    event: ChannelMessageEvent;
  },
  stores: ChannelTriggerDispatcherStores,
): Promise<void> {
  try {
    const task = await stores.taskStore.loadTask(trigger.teamId, trigger.taskId);
    const run = await stores.taskRunStore.enqueueTaskRun({
      teamId: trigger.teamId,
      task,
      context: contextFrom(input.event),
      input: {
        event: input.event,
        [triggerChainInputKey]: [trigger.id],
      },
      trigger: {id: trigger.id, type: "event"},
    });
    await stores.taskRunDispatcher.dispatchTaskRun({
      teamId: trigger.teamId,
      runId: run.runId,
      mode: "start",
    });
    await stores.triggerStore.markEventTriggerRan(trigger, run.runId);
    logInfo("channel_message.trigger_enqueued", {
      teamId: trigger.teamId,
      triggerId: trigger.id,
    });
  } catch (error) {
    logError("channel_message.trigger_failed", {
      teamId: trigger.teamId,
      triggerId: trigger.id,
      error: errorDetails(error),
    });
  }
}

function matchDecision(
  trigger: EventTaskTrigger,
  input: {
    channelId: string;
    event: ChannelMessageEvent;
  },
): {matched: boolean; reason: string} {
  if (trigger.type !== "event") return noMatch("not_event_trigger");
  if (trigger.eventConfig.source !== input.event.type) {
    return noMatch("event_type_mismatch");
  }
  if (!matchesSource(trigger, input)) return noMatch("source_mismatch");
  if (!matchesFilter(trigger, input.event)) return noMatch("filter_mismatch");
  return {matched: true, reason: "matched"};
}

function matchesSource(
  trigger: EventTaskTrigger,
  input: {channelId: string; event: ChannelMessageEvent},
): boolean {
  const connectorId = input.event.type === "emailReceived" ? input.event.connectorId : undefined;
  return messageTargetMatches(trigger.eventConfig.target, {channelId: input.channelId, connectorId});
}

function matchesFilter(
  trigger: EventTaskTrigger,
  event: ChannelMessageEvent,
): boolean {
  const filter = trigger.eventConfig.filter.trim();
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
