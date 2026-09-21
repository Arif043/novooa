import {
  type ChannelMessageEvent,
  messageFromEvent,
  recipientFromEvent,
  senderFromEvent,
} from "../entities/channel-message-event.js";
import {type TaskTriggerStore, type EventTaskTrigger} from
  "../../../scheduling/domain/repositories/task-trigger-store.js";
import {type TaskStore} from
  "../../../task_execution/domain/repositories/task-store.js";
import {type TaskRunStore} from
  "../../../task_execution/domain/repositories/task-run-store.js";
import {type TaskRunDispatcher} from
  "../../../task_execution/domain/repositories/task-run-dispatcher.js";

export type ChannelMessageEventDispatcherPorts = {
  triggerStore: TaskTriggerStore;
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
  taskRunDispatcher: TaskRunDispatcher;
  onTriggerFailure?: (trigger: EventTaskTrigger, error: unknown) => void;
};

export async function dispatchChannelMessageEvent(input: {
  teamId: string;
  channelId: string;
  event: ChannelMessageEvent;
}, ports: ChannelMessageEventDispatcherPorts): Promise<void> {
  const triggers = await ports.triggerStore.listEnabledEventTriggers(input.teamId);
  for (const trigger of triggers) await dispatchTrigger(trigger, input, ports);
}

async function dispatchTrigger(
  trigger: EventTaskTrigger,
  input: {channelId: string; event: ChannelMessageEvent},
  ports: ChannelMessageEventDispatcherPorts,
): Promise<void> {
  if (!matches(trigger, input)) return;
  try {
    const task = await ports.taskStore.loadTask(trigger.teamId, trigger.taskId);
    const run = await ports.taskRunStore.enqueueTaskRun({
      teamId: trigger.teamId, task, context: contextFrom(input.event),
      input: {event: input.event}, trigger: {id: trigger.id, type: "event"},
    });
    await ports.taskRunDispatcher.dispatchTaskRun({teamId: trigger.teamId, runId: run.runId, mode: "start"});
    await ports.triggerStore.markEventTriggerRan(trigger, run.runId);
  } catch (error) {
    ports.onTriggerFailure?.(trigger, error);
  }
}

function matches(trigger: EventTaskTrigger, input: {channelId: string; event: ChannelMessageEvent}): boolean {
  return trigger.type === "event" && trigger.eventConfig.source === input.event.type &&
    matchesSource(trigger, input) && matchesFilter(trigger.eventConfig.filter, input.event);
}

function matchesSource(
  trigger: EventTaskTrigger,
  input: {channelId: string; event: ChannelMessageEvent},
): boolean {
  const connectorId = input.event.type === "emailReceived" ? input.event.connectorId : undefined;
  if (!connectorId) return optionalMatch(trigger.eventConfig.channelId, input.channelId);
  return optionalMatch(trigger.eventConfig.connectorId, connectorId);
}

function optionalMatch(configured: string, actual: string): boolean {
  return configured.trim().length === 0 || configured === actual;
}

function matchesFilter(filter: string, event: ChannelMessageEvent): boolean {
  const expected = filter.trim().toLowerCase();
  return expected.length === 0 || searchableTextFrom(event).toLowerCase().includes(expected);
}

function contextFrom(event: ChannelMessageEvent): string {
  if (event.type === "emailReceived") {
    return ["E-Mail empfangen", `Von: ${event.senderEmail}`, `Betreff: ${event.subject}`, "", event.message].join("\n");
  }
  return [`${eventLabel(event)} empfangen`, `Von: ${event.senderPhoneNumber}`, "", event.message].join("\n");
}

function searchableTextFrom(event: ChannelMessageEvent): string {
  if (event.type === "emailReceived") {
    return [event.senderEmail, event.recipientEmail, event.subject, event.message].join(" ");
  }
  return [senderFromEvent(event), recipientFromEvent(event), messageFromEvent(event)].join(" ");
}

function eventLabel(event: ChannelMessageEvent): string {
  return event.type === "smsMessageReceived" ? "SMS" : "WhatsApp-Nachricht";
}
