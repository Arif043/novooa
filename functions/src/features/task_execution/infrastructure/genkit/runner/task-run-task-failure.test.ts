import assert from "node:assert/strict";
import test from "node:test";
import {ScriptExecutionError} from "../../../domain/entities/script-execution.js";
import {handleTaskRunDispatch} from "./task-run-task.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};
const run = {runId: "run-1", taskId: "task-1", taskTitle: "Aufgabe", context: ""};
const task = {id: "task-1", title: "Aufgabe", objective: "", edges: [], nodes: [{
  id: "kaputt", primitive: "script", title: "kaputt", description: "", outputName: "kaputt",
  config: {primitive: "script", script: "x", attachments: []},
}]};

function storesWith(failures: unknown[], executeScript: () => Promise<never>) {
  return {
    taskStore: {loadTask: async () => task},
    taskRunStore: {
      loadTaskRun: async () => run,
      markRunStarted: async () => undefined,
      markRunFailed: async (_team: string, _run: unknown, error: unknown) => { failures.push(error); },
    },
    scriptExecutorFactory: () => ({execute: executeScript}),
  } as never;
}

test("a failing node is recorded exactly once and does not make the job fail, so it is not retried", async () => {
  const failures: unknown[] = [];
  const stores = storesWith(failures, async () => { throw new ScriptExecutionError("Zeile 1: NameError", ""); });

  await handleTaskRunDispatch({} as never, {teamId: "team-1", runId: "run-1", mode: "start"}, stores, silentLogger as never);

  assert.equal(failures.length, 1, "ein Eintrag je Lauf, nicht zwei");
  assert.match((failures[0] as Error).message, /NameError/);
});

test("an unexpected error is recorded once and still fails the job so it may be retried", async () => {
  const failures: unknown[] = [];
  const stores = storesWith(failures, async () => { throw new Error("nicht erreicht"); });
  (stores as {taskStore: {loadTask: () => Promise<never>}}).taskStore.loadTask = async () => { throw new Error("Aufgabe nicht ladbar"); };

  await assert.rejects(
    handleTaskRunDispatch({} as never, {teamId: "team-1", runId: "run-1", mode: "start"}, stores, silentLogger as never),
    /Aufgabe nicht ladbar/,
  );
  assert.equal(failures.length, 1);
});
