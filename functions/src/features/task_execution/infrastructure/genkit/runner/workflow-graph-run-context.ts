import {
  type TaskRunContext,
  type TaskVariables,
  type WorkflowExecutionScope,
  type WorkflowGraphInput,
  type WorkflowGraphRunner,
} from "../../../domain/executors/node-executor.js";
import {
  resolveVariableTemplateValue,
  resolveVariableTemplates,
  variableTemplateContextFor,
} from "./variable-template.js";
import {
  type NodeExecutionResult,
  type TaskGraphInput,
  type WorkflowGraph,
} from "./task-definition.js";
import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {validateGraph} from "../../../domain/services/task-graph-utils.js";

export type ExecuteWorkflowGraph = (
  graph: WorkflowGraph,
  context: string,
  input: WorkflowGraphInput,
  scope: WorkflowExecutionScope,
) => Promise<NodeExecutionResult[]>;

type TaskRunContextOptions = {
  input: TaskGraphInput;
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
  const templateContext = () => variableTemplateContextFor(
    options.currentGraph,
    options.results,
    options.variables,
    options.scope,
  );
  return {
    rootTask: options.input.taskDefinition,
    currentGraph: options.currentGraph,
    teamId: options.input.teamId,
    input: options.input.input ?? {},
    scope: options.scope,
    results: options.results,
    variables: options.variables,
    teamFileStore: options.runtime.teamFileStore,
    fileContentReader: options.runtime.fileContentReader,
    messageSender: options.runtime.messageSender,
    documentStore: options.runtime.documentStore,
    modelInference: options.runtime.modelInference,
    runGraph: graphRunnerFor(options),
    resolveTemplates: (text) => resolveVariableTemplates(text, templateContext()),
    resolveTemplateValue: (text) => resolveVariableTemplateValue(text, templateContext()),
  };
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
