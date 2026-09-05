import {type NodeExecutionResult} from "./task-definition.js";
import {type TaskVariables} from "../../../domain/executors/node-executor.js";

export function updateTaskVariables(
  variables: TaskVariables,
  result: NodeExecutionResult,
): void {
  if (result.variables === undefined) return;
  for (const key of Object.keys(variables)) delete variables[key];
  Object.assign(variables, result.variables);
}
