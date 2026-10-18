import {type NodeFailure} from "../../../domain/entities/node-failure.js";
import {type Result} from "neverthrow";
import {
  type TaskRunContext,
  type WorkflowExecutionScope,
  type WorkflowGraphRunner,
} from "../../../domain/executors/node-executor.js";
import {
  TemplateExpressionResolver,
  templateExpressionContextFor,
} from "./template-expression-resolver.js";
import {
  type NodeExecutionResult,
  type TaskGraphInput,
  type WorkflowGraph,
} from "./task-definition.js";
import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {triggerChainFrom} from "../../../../scheduling/domain/entities/trigger-chain.js";
import {TriggerChainTeamFileStore} from "../../../domain/services/trigger-chain-file-store.js";
import {validateGraph} from "../../../domain/services/task-graph-utils.js";

export type ExecuteWorkflowGraph = (
  graph: WorkflowGraph,
  scope: WorkflowExecutionScope,
) => Promise<Result<NodeExecutionResult[], NodeFailure>>;

type TaskRunContextOptions = {
  input: TaskGraphInput;
  runtime: TaskGraphRuntime;
  currentGraph: WorkflowGraph;
  results: Map<string, NodeExecutionResult>;
  scope: WorkflowExecutionScope;
  executeGraph: ExecuteWorkflowGraph;
};

export function createTaskRunContext(
  options: TaskRunContextOptions,
): TaskRunContext {
  const templateResolver = new TemplateExpressionResolver(() => templateContextFor(options));
  const {teamFileStore, ...services} = passedThroughServices(options.runtime);
  return {
    ...services,
    rootTask: options.input.taskDefinition,
    currentGraph: options.currentGraph,
    teamId: options.input.teamId,
    input: options.input.input ?? {},
    scope: options.scope,
    results: options.results,
    teamFileStore: new TriggerChainTeamFileStore(
      teamFileStore,
      triggerChainFrom(options.input.input),
    ),
    runGraph: graphRunnerFor(options),
    templateExpressionResolver: templateResolver,
  };
}

/** Alles aus der Laufzeit, was der Kontext nicht selbst ersetzt, wird unverändert weitergereicht. */
function passedThroughServices(runtime: TaskGraphRuntime) {
  const {
    objectStore: _objectStore, knowledgeBaseStore: _knowledgeBaseStore, logger: _logger, skillContentReader: _skillContentReader, employeeStore: _employeeStore,
    languageModelResolver: _languageModelResolver, languageModelDefaultsStore: _languageModelDefaultsStore, scriptExecutorFactory: _scriptExecutorFactory,
    executorRegistry: _executorRegistry,
    ...services
  } = runtime;
  return services;
}

function templateContextFor(options: TaskRunContextOptions) {
  return templateExpressionContextFor(
    options.currentGraph,
    options.results,
    options.scope,
  );
}

function graphRunnerFor(options: TaskRunContextOptions): WorkflowGraphRunner {
  return async (graph, scope = {}) => {
    validateGraph(graph);
    return options.executeGraph(graph, scopeFor(options, scope));
  };
}

function scopeFor(
  options: TaskRunContextOptions,
  scope: WorkflowExecutionScope,
): WorkflowExecutionScope {
  return {
    ...scope,
    global: {
      ...options.scope.global,
      ...globalContextFor(options),
    },
  };
}

function globalContextFor(
  options: TaskRunContextOptions,
): Record<string, unknown> {
  const context = templateExpressionContextFor(
    options.currentGraph,
    options.results,
  );
  return {
    input: options.input.input ?? {},
    // Zweige und „Für jedes Element“ sehen die Werte der äußeren Ebene unter
    // denselben flachen Namen wie dort (`{{Gefunden}}`, `{{global.Gefunden}}`).
    ...Object.fromEntries(Object.entries(context.flatOutputs).map(([name, output]) => [
      name,
      output.value,
    ])),
  };
}
