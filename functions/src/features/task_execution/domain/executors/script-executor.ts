import {type NodeFailure} from "../entities/node-failure.js";
import {type Result} from "neverthrow";
import {type ScriptExecutionRequest, type ScriptExecutionResult, type ScriptWorkspace} from "../entities/script-execution.js";

/** Ein Fehler im Script selbst ist eine Failure (`scriptFailed`) samt Konsole; scheitert der Dienst, wirft die Infrastruktur. */
export interface ScriptExecutor {
  execute(request: ScriptExecutionRequest): Promise<Result<ScriptExecutionResult, NodeFailure>>;
}

/** Baut den Executor für einen Baustein; der Workspace trägt dessen angehängte Dateien. */
export type ScriptExecutorFactory = (workspace?: ScriptWorkspace) => ScriptExecutor;
