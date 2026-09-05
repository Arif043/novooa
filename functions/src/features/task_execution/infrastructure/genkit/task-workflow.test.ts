import assert from "node:assert/strict";
import test from "node:test";
import {type TaskRunDispatchInput} from "../../domain/repositories/task-run-dispatcher.js";
import {type EnqueueTaskRunInput} from "../../domain/repositories/task-run-store.js";
import {createGenkitTaskWorkflowWithAi} from "./task-workflow.js";

test("starts a run through domain ports for the authenticated team", async () => {
  const loadedTeams: string[] = [];
  const dispatches: unknown[] = [];
  const workflow = createGenkitTaskWorkflowWithAi({} as never, {
    taskStore: {
      async loadTask(teamId: string) {
        loadedTeams.push(teamId);
        return {
          id: "task-1",
          title: "Beleg pruefen",
          objective: "",
          nodes: [],
          edges: [],
        } as never;
      },
    },
    taskRunStore: {
      async enqueueTaskRun(input: EnqueueTaskRunInput) {
        assert.equal(input.teamId, "team-1");
        assert.equal(input.context, "Eingang pruefen");
        return {
          runId: "run-1",
          taskId: "task-1",
          taskTitle: "Beleg pruefen",
          context: input.context,
        };
      },
    },
    taskRunDispatcher: {
      async dispatchTaskRun(input: TaskRunDispatchInput) {
        dispatches.push(input);
      },
    },
    teamContextStore: {
      async currentTeamIdForUid(uid: string) {
        assert.equal(uid, "user-1");
        return "team-1";
      },
    },
    teamFileStore: {},
    workerStores: {},
  } as never);

  const output = await workflow.start(
    {taskId: "task-1", context: "Eingang pruefen"},
    {uid: "user-1"},
  );

  assert.deepEqual(loadedTeams, ["team-1"]);
  assert.deepEqual(dispatches, [{teamId: "team-1", runId: "run-1", mode: "start"}]);
  assert.deepEqual(output, {runId: "run-1", taskId: "task-1", status: "queued"});
});
