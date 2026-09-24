import assert from "node:assert/strict";
import test from "node:test";
import {
  LocalRuntimeRealtimeNotifier,
  type LocalRuntimeRealtimeSubscriber,
} from "./local-runtime-realtime-notifier.js";

function recordingSubscriber(): LocalRuntimeRealtimeSubscriber & {messages: string[]} {
  const messages: string[] = [];
  return {messages, send: (message: string) => messages.push(message)};
}

test("benachrichtigt nur Subscriber des betroffenen Topics", () => {
  const notifier = new LocalRuntimeRealtimeNotifier();
  const taskRunsSubscriber = recordingSubscriber();
  const tasksSubscriber = recordingSubscriber();
  notifier.subscribe("task-runs", taskRunsSubscriber);
  notifier.subscribe("tasks", tasksSubscriber);

  notifier.publish("task-runs");

  assert.deepEqual(taskRunsSubscriber.messages, [
    JSON.stringify({type: "changed", topic: "task-runs"}),
  ]);
  assert.deepEqual(tasksSubscriber.messages, []);
});

test("ignoriert publish ohne registrierte Subscriber", () => {
  const notifier = new LocalRuntimeRealtimeNotifier();

  assert.doesNotThrow(() => notifier.publish("task-runs"));
});

test("benachrichtigt nach unsubscribe nicht mehr", () => {
  const notifier = new LocalRuntimeRealtimeNotifier();
  const subscriber = recordingSubscriber();
  notifier.subscribe("task-runs", subscriber);
  notifier.unsubscribe("task-runs", subscriber);

  notifier.publish("task-runs");

  assert.deepEqual(subscriber.messages, []);
});

test("unsubscribeAll entfernt einen Subscriber aus jedem Topic", () => {
  const notifier = new LocalRuntimeRealtimeNotifier();
  const subscriber = recordingSubscriber();
  notifier.subscribe("task-runs", subscriber);
  notifier.subscribe("tasks", subscriber);
  notifier.unsubscribeAll(subscriber);

  notifier.publish("task-runs");
  notifier.publish("tasks");

  assert.deepEqual(subscriber.messages, []);
});

test("benachrichtigt mehrere Subscriber desselben Topics", () => {
  const notifier = new LocalRuntimeRealtimeNotifier();
  const first = recordingSubscriber();
  const second = recordingSubscriber();
  notifier.subscribe("task-runs", first);
  notifier.subscribe("task-runs", second);

  notifier.publish("task-runs");

  assert.equal(first.messages.length, 1);
  assert.equal(second.messages.length, 1);
});
