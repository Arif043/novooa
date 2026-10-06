import {genkit, type GenkitBeta} from "genkit/beta";
import {
  type ReviewTaskWorkflowInput,
  type ReviewTaskWorkflowOutput,
  type StartTaskWorkflowInput,
  type StartTaskWorkflowOutput,
  type TaskWorkflow,
  type TaskWorkflowContext,
} from "../../domain/usecases/task-workflow.js";
import {type TaskStore} from "../../domain/repositories/task-store.js";
import {type TaskRunStore} from "../../domain/repositories/task-run-store.js";
import {type TaskRunDispatcher} from "../../domain/repositories/task-run-dispatcher.js";
import {type TeamFileStore} from "../../../files/domain/repositories/team-file-store.js";
import {type TeamContextStore} from "../../../teams/domain/repositories/team-context-store.js";
import {responseOutputsForTaskRun} from "../../domain/usecases/task-run-response-outputs.js";
import {
  type ApplicationLogger,
  withExceptionLogging,
} from "../../../../shared/logging/application-logger.js";
import {handleTaskRunDispatch} from "./runner/task-run-task.js";
import {type TaskRunWorkerStores} from "./runner/task-run-worker.js";
import {aiProviderPlugins} from "./runner/ai-models.js";

export type GenkitTaskWorkflowDependencies = {
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
  taskRunDispatcher: TaskRunDispatcher;
  teamContextStore: TeamContextStore;
  teamFileStore: TeamFileStore;
  workerStores: TaskRunWorkerStores;
  logger: ApplicationLogger;
};

export function createGenkitTaskWorkflow(
  dependencies: GenkitTaskWorkflowDependencies,
): TaskWorkflow {
  return createGenkitTaskWorkflowWithAi(
    genkit({plugins: aiProviderPlugins()}),
    dependencies,
  );
}

export function createGenkitTaskWorkflowWithAi(
  ai: GenkitBeta,
  dependencies: GenkitTaskWorkflowDependencies,
): TaskWorkflow {
  return {
    start: (input, context) => startTaskWorkflow(input, context, dependencies),
    review: (input, context) => reviewTaskWorkflow(input, context, dependencies),
    dispatch: (input) => handleTaskRunDispatch(
      ai,
      input,
      dependencies.workerStores,
      dependencies.logger,
    ),
  };
}

async function startTaskWorkflow(
  input: StartTaskWorkflowInput,
  context: TaskWorkflowContext,
  dependencies: GenkitTaskWorkflowDependencies,
): Promise<StartTaskWorkflowOutput> {
  let title = "";
  try {
    const teamId = await dependencies.teamContextStore.currentTeamIdForUid(context.uid);
    const task = await dependencies.taskStore.loadTask(teamId, input.taskId);
    title = task.title;
    const run = await dependencies.taskRunStore.enqueueTaskRun({
      teamId,
      task,
      context: input.context,
    });
    await dependencies.taskRunDispatcher.dispatchTaskRun({
      teamId,
      runId: run.runId,
      mode: "start",
    });
    return {runId: run.runId, taskId: run.taskId, status: "queued"};
  } catch (error) {
    dependencies.logger.exception("run_task_definition_flow.failed", error, {
      taskId: input.taskId,
      title,
    });
    throw error;
  }
}

async function reviewTaskWorkflow(
  input: ReviewTaskWorkflowInput,
  context: TaskWorkflowContext,
  dependencies: GenkitTaskWorkflowDependencies,
): Promise<ReviewTaskWorkflowOutput> {
  return withExceptionLogging(dependencies.logger, "review_task_run.failed", async () => {
    const teamId = await dependencies.teamContextStore.currentTeamIdForUid(context.uid);
    const reviewableRun = await dependencies.taskRunStore.loadReviewableRun(
      teamId,
      input.runId,
    );
    if (input.decision === "reject") {
      await dependencies.taskRunStore.rejectTaskRun(teamId, reviewableRun.run.runId);
      // Ein abgelehnter Run ist beendet und wird nie fortgesetzt; seine Schritte braucht niemand mehr.
      await dependencies.workerStores.stepJournal?.clear(teamId, reviewableRun.run.runId);
      return {runId: input.runId, status: "rejected"};
    }
    const responseOutputs = await responseOutputsForTaskRun(
      reviewableRun.resumeState,
      input.output,
      input.formValues,
      teamId,
      dependencies.teamFileStore,
    );
    await dependencies.taskRunStore.approveTaskRun(
      teamId,
      reviewableRun.run.runId,
      responseOutputs,
    );
    await dependencies.taskRunDispatcher.dispatchTaskRun({
      teamId,
      runId: reviewableRun.run.runId,
      mode: "resume",
    });
    return {runId: input.runId, status: "queued"};
  }, {runId: input.runId});
}
