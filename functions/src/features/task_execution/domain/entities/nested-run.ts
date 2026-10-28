import {type FailedNode} from "./node-execution-failure.js";
import {type NodeExecutionResult} from "./task.js";

/**
 * Ein Aufruf des Teilgraphen eines Zweigs oder einer Schleife: was darin lief. Ein Zweig hat
 * einen Aufruf, eine Schleife einen je Runde ([iteration], ab 0). Bricht ein innerer Baustein
 * ab, steht er in [failed]; [results] sind dann die bis dahin fertigen.
 */
export type NestedRun = {
  iteration?: number;
  results: NodeExecutionResult[];
  failed?: FailedNode;
};
