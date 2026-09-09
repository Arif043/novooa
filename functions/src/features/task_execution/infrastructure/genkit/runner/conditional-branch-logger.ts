import {
  type ConditionalBranchFinished,
  type ConditionalBranchObserver,
  type ConditionalBranchStarted,
} from "../../../domain/executors/conditional-node-executor.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

export function conditionalBranchLogger(
  logger: ApplicationLogger,
): ConditionalBranchObserver {
  return {
    started: (event) => logBranchStarted(logger, event),
    finished: (event) => logBranchFinished(logger, event),
  };
}

function logBranchStarted(logger: ApplicationLogger, event: ConditionalBranchStarted): void {
  logger.readableInfo([
    `[Zweig startet] ${event.branchLabel}`,
    `Bedingung: ${event.node.title} (${event.node.id})`,
    `Bausteine: ${event.nodeCount} | Kanten: ${event.edgeCount}`,
  ].join("\n"));
}

function logBranchFinished(logger: ApplicationLogger, event: ConditionalBranchFinished): void {
  logger.readableInfo([
    `[Zweig beendet] ${event.branchLabel}`,
    `Bausteine ausgeführt: ${event.resultCount}`,
    `Ausgabe: ${event.outputLength} Zeichen`,
  ].join("\n"));
}
