import {type ScriptExecutionRequest, type ScriptExecutionResult} from "../entities/script-execution.js";

export interface ScriptExecutor {
  execute(request: ScriptExecutionRequest): Promise<ScriptExecutionResult>;
}
