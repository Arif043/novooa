import assert from "node:assert/strict";
import test from "node:test";
import {type EventTaskTrigger, type TaskTriggerStore} from "../../scheduling/domain/repositories/task-trigger-store.js";
import {PluginNotFoundError} from "./entities/stored-plugin.js";
import {PluginRunError, type PluginTriggerPoll, type PluginTriggerRunner} from "./repositories/plugin-runner.js";
import {type PluginTriggerStateStore} from "./repositories/plugin-trigger-state-store.js";
import {pollPluginTriggers, type PollPluginTriggersPorts} from "./usecases/poll-plugin-triggers.js";

const trigger = (id: string, source = "plugin", pluginId = "hallo"): EventTaskTrigger => ({
  id, teamId: "team-1", taskId: `task-${id}`, type: "event",
  eventConfig: {
    source, target: {kind: "any"}, fileKinds: [], filter: "",
    plugin: {pluginId, type: "tick", settings: {interval: 5}},
  },
});

function setup(triggers: EventTaskTrigger[], runner: PluginTriggerRunner, failingEnqueue = false) {
  const enqueued: {taskId: string; context: string; input: unknown}[] = [];
  const written = new Map<string, unknown>();
  const stored = new Map<string, unknown>([["a", {cursor: 1}]]);
  const failures: unknown[] = [];
  const ran: string[] = [];
  const states: PluginTriggerStateStore = {
    read: (id) => Promise.resolve(stored.get(id)),
    write: (id, state) => { written.set(id, state); return Promise.resolve(); },
    delete: () => Promise.resolve(),
  };
  const ports = {
    triggerStore: {
      listEnabledEventTriggers: () => Promise.resolve(triggers),
      markEventTriggerRan: (event: EventTaskTrigger) => { ran.push(event.id); return Promise.resolve(); },
    } as unknown as TaskTriggerStore,
    taskStore: {loadTask: (_team: string, taskId: string) => Promise.resolve({id: taskId})},
    taskRunStore: {
      enqueueTaskRun: (request: {task: {id: string}; context: string; input: unknown}) => {
        if (failingEnqueue) return Promise.reject(new Error("voll"));
        enqueued.push({taskId: request.task.id, context: request.context, input: request.input});
        return Promise.resolve({runId: `run-${enqueued.length}`});
      },
    },
    taskRunDispatcher: {dispatchTaskRun: () => Promise.resolve()},
    runner, states, teamId: "team-1",
    onFailure: (failure: unknown) => failures.push(failure),
  } as unknown as PollPluginTriggersPorts;
  return {ports, enqueued, written, failures, ran};
}

const events = (...names: string[]) => names.map((name) => ({context: `Ereignis ${name}`, data: {name}}));

test("jedes Ereignis startet die Aufgabe, danach wird der neue Zustand gespeichert", async () => {
  const polls: PluginTriggerPoll[] = [];
  const {ports, enqueued, written, ran} = setup([trigger("a")], {
    pollTrigger: (poll) => { polls.push(poll); return Promise.resolve({events: events("eins", "zwei"), state: {cursor: 3}}); },
  });

  await pollPluginTriggers(ports);

  assert.deepEqual(polls, [{pluginId: "hallo", triggerType: "tick", settings: {interval: 5}, state: {cursor: 1}}]);
  assert.deepEqual(enqueued.map((run) => run.context), ["Ereignis eins", "Ereignis zwei"]);
  assert.deepEqual((enqueued[0]?.input as {event: unknown}).event, {source: "plugin", pluginId: "hallo", type: "tick", data: {name: "eins"}});
  assert.deepEqual(written.get("a"), {cursor: 3});
  assert.deepEqual(ran, ["a", "a"]);
});

test("andere Quellen werden nicht abgefragt", async () => {
  const polls: PluginTriggerPoll[] = [];
  const {ports} = setup([trigger("a", "emailReceived")], {
    pollTrigger: (poll) => { polls.push(poll); return Promise.resolve({events: [], state: null}); },
  });

  await pollPluginTriggers(ports);

  assert.deepEqual(polls, []);
});

test("ein fehlerhafter Trigger hält die anderen nicht auf und wird gemeldet", async () => {
  const {ports, enqueued, failures} = setup([trigger("a", "plugin", "kaputt"), trigger("b")], {
    pollTrigger: (poll) => poll.pluginId === "kaputt"
      ? Promise.reject(new PluginRunError("abgestürzt"))
      : Promise.resolve({events: events("ok"), state: 1}),
  });

  await pollPluginTriggers(ports);

  assert.equal(enqueued.length, 1);
  assert.equal(failures.length, 1);
  assert.match(String((failures[0] as {error: Error}).error), /abgestürzt/);
});

test("ein nicht installiertes Plugin ist kein Fehler", async () => {
  const {ports, failures} = setup([trigger("a")], {pollTrigger: () => Promise.reject(new PluginNotFoundError("hallo"))});

  await pollPluginTriggers(ports);

  assert.deepEqual(failures, []);
});

test("scheitert das Einreihen, bleibt der Zustand unverändert — das Ereignis kommt erneut", async () => {
  const {ports, written, failures} = setup([trigger("a")], {
    pollTrigger: () => Promise.resolve({events: events("eins"), state: {cursor: 9}}),
  }, true);

  await pollPluginTriggers(ports);

  assert.equal(written.size, 0);
  assert.equal(failures.length, 1);
});
