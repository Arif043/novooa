import {type ScriptExecutionRequest, type ScriptExecutionResult, type ScriptWorkspace} from "../entities/script-execution.js";

export interface ScriptExecutor {
  execute(request: ScriptExecutionRequest): Promise<ScriptExecutionResult>;
}

/** Baut den Executor für einen Baustein; der Workspace trägt dessen angehängte Dateien. */
export type ScriptExecutorFactory = (workspace?: ScriptWorkspace) => ScriptExecutor;
