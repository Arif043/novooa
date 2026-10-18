import {NodeFailure} from "../../../domain/entities/node-failure.js";

/**
 * Ein Baustein in einem verschachtelten Plan (Zweig, Schleife) ist mit einer
 * Failure gescheitert. Der Port `runGraph` meldet das noch per Exception;
 * der Runner macht beim äußeren Baustein wieder eine Failure daraus.
 */
export class NestedNodeFailedException extends Error {
  constructor(readonly failure: NodeFailure) {
    super(failure.message);
    this.name = "NestedNodeFailedException";
  }
}

/** Was `runGraph` für einen gescheiterten verschachtelten Plan wirft. */
export function nestedFailureCause(cause: unknown): unknown {
  return cause instanceof NodeFailure ? new NestedNodeFailedException(cause) : cause;
}
