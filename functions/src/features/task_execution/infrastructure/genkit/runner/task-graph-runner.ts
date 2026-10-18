import { type GenkitBeta } from "genkit/beta";
import {type TaskVariables, type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";
import {type TaskRunStepScope} from "../../../domain/entities/task-run-step-key.js";
import {type JournaledStep, journaledStep, rootStepScope, runJournaledNode} from "./journaled-node-run.js";
import {
  type NodeOutputValue,
  type TaskGraphInput,
  type TaskGraphOutput,
  type WorkflowGraph,
  type TaskResumeState,
} from "./task-definition.js";
import {
  completedOutput,
  type InitialNodeRunState,
  newResults,
  failedNodeExecution,
  nodeExecutionFailure,
  type NodeRunState,
  orderedResults,
  pausedOutput,
  remainingNodes,
  resumedState,
  resultsMapFrom,
} from "./task-graph-state.js";
import {
  contextFor,
  nextRunnableIndex,
  shouldSkipNode,
  skipInactiveBranches,
  validateGraph,
} from "../../../domain/services/task-graph-utils.js";
import {type NodeExecutionFailure} from "../../../domain/entities/node-execution-failure.js";
import {nestedNodeFailureOf} from "./nested-node-failure.js";
import {err, ok, type Result, ResultAsync} from "neverthrow";
import {formatTaskFinished, formatTaskStarted} from "./structured-logger.js";
import {
  logNodeHeaderLine,
  logSkippedBranches,
  runNodeWithTrail,
} from "./task-node-runner.js";
import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {updateTaskVariables} from "./task-run-variables.js";
import {createTaskRunContext, type ExecuteWorkflowGraph} from "./workflow-graph-run-context.js";
export function executeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
): ResultAsync<TaskGraphOutput, NodeExecutionFailure> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  return new ResultAsync(runNodes(ai, input, runtime, {stepScope: rootStepScope(input, runtime.stepJournal)}))
    .map((runState) => finishedOutput(input, runState, runtime));
}

export function resumeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  resumeState: TaskResumeState,
  responseOutputs: Record<string, NodeOutputValue>,
  runtime: TaskGraphRuntime,
): ResultAsync<TaskGraphOutput, NodeExecutionFailure> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  return new ResultAsync(runNodes(ai, input, runtime, {
    initialState: resumedState(resumeState, responseOutputs),
    stepScope: rootStepScope(input, runtime.stepJournal),
  }))
    .map((runState) => runState.status === "waitingForApproval"
      ? pausedOutput(input, runState)
      : completedOutput(input, runState.nodeResults));
}

function finishedOutput(input: TaskGraphInput, runState: NodeRunState, runtime: TaskGraphRuntime): TaskGraphOutput {
  if (runState.status === "waitingForApproval") return pausedOutput(input, runState);
  const results = runState.nodeResults;
  const output = completedOutput(input, results);
  runtime.logger.readableInfo(formatTaskFinished(
    output.taskId,
    results.filter((result) => result.status === "executed").length,
    results.filter((result) => result.status === "skipped").length,
    output.finalOutput.length,
  ));
  return output;
}

type GraphRunOptions = {
  initialState?: InitialNodeRunState;
  scope?: WorkflowExecutionScope;
  graph?: WorkflowGraph;
  /** Wo die Schritte dieses Graphen im Journal stehen; fehlt, wenn nicht journalisiert wird. */
  stepScope?: TaskRunStepScope;
};

async function runNodes(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
  options: GraphRunOptions = {},
): Promise<Result<NodeRunState, NodeExecutionFailure>> {
  const {initialState, scope = {}, graph = input.taskDefinition} = options;
  const remaining = remainingNodes(graph, initialState);
  const results = resultsMapFrom(initialState?.nodeResults ?? []);
  const skippedNodeIds = new Set(initialState?.skippedNodeIds ?? []);
  const variables = {...initialState?.variables};

  while (remaining.length > 0) {
    const index = nextRunnableIndex(
      remaining,
      graph.edges,
      results,
    );
    if (index === -1) throw new Error("Task graph contains a cycle.");
    const node = remaining.splice(index, 1)[0];
    const context = contextFor(variables);
    const skipNode = shouldSkipNode(
      node,
      graph,
      results,
      skippedNodeIds,
    );
    const startedAt = Date.now();
    logNodeHeaderLine(runtime.logger, node, input.taskDefinition.id, graph, context, skipNode, results);
    const step = journaledStep(runtime.stepJournal, options.stepScope, node.id);
    // Bausteine liefern Failures als Wert; was dennoch geworfen wird (Infrastruktur, noch nicht
    // umgestellte Executoren), wird hier, an der Grenze, ebenfalls zur Failure.
    const resultOrFailure = await ResultAsync.fromPromise(runJournaledNode(step, () => runNodeWithTrail(ai, {
      node,
      context,
      runContext: createTaskRunContext({
        input,
        context,
        runtime,
        currentGraph: graph,
        results,
        variables,
        scope,
        executeGraph: embeddedGraphRunner(ai, input, runtime, variables, step),
      }),
      skipNode,
      startedAt,
      objectStore: runtime.objectStore,
      skillContentReader: runtime.skillContentReader,
      employeeStore: runtime.employeeStore,
      knowledgeBaseStore: runtime.knowledgeBaseStore,
      languageModelResolver: runtime.languageModelResolver,
      languageModelDefaultsStore: runtime.languageModelDefaultsStore,
      scriptExecutorFactory: runtime.scriptExecutorFactory,
      executorRegistry: runtime.executorRegistry,
      logger: runtime.logger,
    }), runtime.logger), (error) => nodeExecutionFailure(node, error, newResults(graph, results, initialState)))
      .andThen((nodeResultOrFailure) => nodeResultOrFailure.mapErr(
        (failure) => failedNodeExecution(node, failure, newResults(graph, results, initialState)),
      ));
    if (resultOrFailure.isErr()) return err(resultOrFailure.error);
    const result = resultOrFailure.value;
    updateTaskVariables(variables, result);
    results.set(node.id, result);
    skipInactiveBranches(node, graph, result, skippedNodeIds);
    logSkippedBranches(runtime.logger, node, input.taskDefinition.id, result, skippedNodeIds);
    if (result.status === "waitingForApproval") {
      return ok({
        status: "waitingForApproval",
        nodeResults: orderedResults(graph, results),
        variables: {...variables},
        remainingNodeIds: remaining.map((item) => item.id),
        skippedNodeIds: Array.from(skippedNodeIds),
        waitingNodeId: node.id,
      });
    }
  }

  return ok({
    status: "completed",
    nodeResults: orderedResults(graph, results),
  });
}

/** Jeder Aufruf eines Container-Bausteins (z. B. eine Schleifen-Iteration) erhält einen eigenen Journal-Bereich. */
function embeddedGraphRunner(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
  variables: TaskVariables,
  containerStep: JournaledStep | undefined,
): ExecuteWorkflowGraph {
  let callIndex = 0;
  return async (embeddedGraph, _embeddedContext, embeddedScope) => {
    const stepScope = containerStep?.key.nested(callIndex++);
    const initialState = {nodeResults: [], variables, remainingNodeIds: embeddedGraph.nodes.map((item) => item.id), skippedNodeIds: []};
    const stateOrFailure = await runNodes(ai, input, runtime, {initialState, scope: embeddedScope, graph: embeddedGraph, stepScope});
    // Der äußere Baustein bekommt die Failure des inneren; eine innere Exception wird zu `unexpected`.
    return stateOrFailure.map((state) => state.nodeResults).mapErr(nestedNodeFailureOf);
  };
}
