import {type NestedRun} from "../../../domain/entities/nested-run.js";
import {type NodeExecutionFailure} from "../../../domain/entities/node-execution-failure.js";
import {type NodeExecutionResult} from "../../../domain/entities/task.js";
import {type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";

/**
 * Sammelt, was in den Teilgraphen eines Bausteins lief — die Zweige und Schleifen selbst
 * geben nur ihr Gesamtergebnis zurück, die inneren Ergebnisse gingen sonst verloren.
 */
export class NestedRunCollector {
  private readonly collected: NestedRun[] = [];

  completed(scope: WorkflowExecutionScope, results: NodeExecutionResult[]): void {
    this.collected.push({...iterationOf(scope), results});
  }

  failed(scope: WorkflowExecutionScope, failure: NodeExecutionFailure): void {
    this.collected.push({...iterationOf(scope), results: failure.completedNodeResults, failed: failure.failedNode});
  }

  get runs(): readonly NestedRun[] {
    return this.collected;
  }
}

function iterationOf(scope: WorkflowExecutionScope): {iteration?: number} {
  const index = scope.iteration?.index;
  return index === undefined ? {} : {iteration: index};
}
