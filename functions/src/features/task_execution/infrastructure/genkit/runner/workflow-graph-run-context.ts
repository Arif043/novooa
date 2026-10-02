import {
  type TaskRunContext,
  type TaskVariables,
  type WorkflowExecutionScope,
  type WorkflowGraphInput,
  type WorkflowGraphRunner,
} from "../../../domain/executors/node-executor.js";
import {
  TemplateExpressionResolver,
  variableTemplateContextFor,
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
  context: string,
  input: WorkflowGraphInput,
  scope: WorkflowExecutionScope,
) => Promise<NodeExecutionResult[]>;

type TaskRunContextOptions = {
  input: TaskGraphInput;
  context: string;
  runtime: TaskGraphRuntime;
  currentGraph: WorkflowGraph;
  results: Map<string, NodeExecutionResult>;
  variables: TaskVariables;
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
    context: options.context,
    rootTask: options.input.taskDefinition,
    currentGraph: options.currentGraph,
    teamId: options.input.teamId,
    input: options.input.input ?? {},
    scope: options.scope,
    results: options.results,
    variables: options.variables,
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
    objectStore: _objectStore, knowledgeBaseStore: _knowledgeBaseStore, logger: _logger, skillContentReader: _skillContentReader,
    languageModelResolver: _languageModelResolver, languageModelDefaultsStore: _languageModelDefaultsStore,
    ...services
  } = runtime;
  return services;
}

function templateContextFor(options: TaskRunContextOptions) {
  return variableTemplateContextFor(
    options.currentGraph,
    options.results,
    options.variables,
    options.scope,
  );
}

function graphRunnerFor(options: TaskRunContextOptions): WorkflowGraphRunner {
  return async (graph, context, input = {}) => {
    validateGraph(graph);
    return options.executeGraph(graph, context, input, scopeFor(options, input));
  };
}

function scopeFor(
  options: TaskRunContextOptions,
  input: WorkflowGraphInput,
): WorkflowExecutionScope {
  return {
    ...input.scope,
    global: {
      ...options.scope.global,
      ...globalContextFor(options),
    },
  };
}

function globalContextFor(
  options: TaskRunContextOptions,
): Record<string, unknown> {
  const context = variableTemplateContextFor(
    options.currentGraph,
    options.results,
    options.variables,
  );
  return {
    input: options.input.input ?? {},
    variables: options.variables,
    ...Object.fromEntries(Object.entries(context.nodeOutputs).map(([name, outputs]) => [
      name,
      Object.fromEntries(Object.entries(outputs).map(([output, value]) => [
        output,
        value.value,
      ])),
    ])),
  };
}
