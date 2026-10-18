import {type NodeExecutionResult} from "../entities/task.js";
import {type NodeResultOrFailure} from "./node-executor.js";

/** Das Ergebnis eines Bausteins, der erfolgreich sein muss; sonst scheitert der Test mit der Failure. */
export function succeeded(resultOrFailure: NodeResultOrFailure): NodeExecutionResult {
  if (resultOrFailure.isErr()) throw new Error(`Baustein gescheitert: ${resultOrFailure.error.code} ${resultOrFailure.error.message}`);
  return resultOrFailure.value;
}
