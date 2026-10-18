import {type NodeExecutionFailure} from "../../../domain/entities/node-execution-failure.js";
import {NodeFailure} from "../../../domain/entities/node-failure.js";
import {nodeFailures} from "../../../domain/entities/node-failures.js";

/** Was der äußere Baustein (Zweig, Schleife) vom gescheiterten inneren Plan erfährt. */
export function nestedNodeFailureOf(failure: NodeExecutionFailure): NodeFailure {
  if (failure.cause instanceof NodeFailure) return failure.cause;
  return nodeFailures.unexpected(failure.failedNode.message, failure.failedNode.console);
}
