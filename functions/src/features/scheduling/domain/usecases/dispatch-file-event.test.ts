import assert from "node:assert/strict";
import test from "node:test";
import {type FileEvent} from "../../../files/domain/entities/file-event.js";
import {eventTriggerConfigFrom} from "../entities/event-trigger-config.js";
import {type EventTaskTrigger} from "../repositories/task-trigger-store.js";
import {DispatchFileEvent} from "./dispatch-file-event.js";

const event: FileEvent = {
  type: "fileCreated", teamId: "team-1", fileId: "f1", versionId: "v1", displayName: "a.txt",
  contentType: "text/plain", sizeBytes: 1, folderId: "ordner", occurredAt: "2026-10-02T10:00:00Z",
};

function trigger(id: string, eventConfig: Record<string, unknown>): EventTaskTrigger {
  return {id, teamId: "team-1", taskId: `task-${id}`, type: "event",
    eventConfig: eventTriggerConfigFrom({source: "fileCreated", ...eventConfig})};
}

function dispatcherFor(
  triggers: EventTaskTrigger[],
  failures: unknown[] = [],
  broken: {taskId?: string; triggerList?: boolean} = {},
) {
  const started: Array<{taskId: string; input: unknown; context: string}> = [];
  const ran: string[] = [];
  const dispatcher = new DispatchFileEvent({
    triggerStore: {
      listEnabledEventTriggers: async () => {
        if (broken.triggerList) throw new Error("DB weg");
        return triggers;
      },
      markEventTriggerRan: async (item: EventTaskTrigger) => {ran.push(item.id);},
    } as never,
    taskStore: {
      loadTask: async (_team: string, taskId: string) => {
        if (taskId === broken.taskId) throw new Error("Aufgabe fehlt");
        return {id: taskId};
      },
    } as never,
    taskRunStore: {
      enqueueTaskRun: async (input: {task: {id: string}; input: unknown; context: string}) => {
        started.push({taskId: input.task.id, input: input.input, context: input.context});
        return {runId: `run-${input.task.id}`};
      },
    } as never,
    taskRunDispatcher: {dispatchTaskRun: async () => undefined} as never,
    folders: {chainOf: async () => ["ordner", "wurzel"]},
    onFailure: (error) => failures.push(error),
  });
  return {dispatcher, started, ran};
}

test("startet nur Trigger, deren Ziel zum Ereignis passt", async () => {
  const {dispatcher, started, ran} = dispatcherFor([
    trigger("alle", {}),
    trigger("wurzel", {target: {kind: "folder", id: "wurzel", includeSubfolders: true}}),
    trigger("anderer", {target: {kind: "folder", id: "anderer", includeSubfolders: true}}),
    trigger("geloescht", {source: "fileDeleted"}),
  ]);

  await dispatcher.publish(event);

  assert.deepEqual(started.map((run) => run.taskId), ["task-alle", "task-wurzel"]);
  assert.deepEqual(ran, ["alle", "wurzel"]);
  assert.deepEqual(started[0].input, {event});
  assert.match(started[0].context, /Datei erstellt/);
});

test("ein fehlschlagender Trigger stoppt die übrigen nicht", async () => {
  const failures: unknown[] = [];
  const {dispatcher, ran} = dispatcherFor(
    [trigger("kaputt", {}), trigger("heil", {})], failures, {taskId: "task-kaputt"},
  );

  await dispatcher.publish(event);

  assert.deepEqual(ran, ["heil"]);
  assert.equal(failures.length, 1);
});

test("Fehler beim Laden der Trigger werden gemeldet statt geworfen", async () => {
  const failures: unknown[] = [];
  const {dispatcher} = dispatcherFor([], failures, {triggerList: true});

  await dispatcher.publish(event);

  assert.equal(failures.length, 1);
});
