import {
  type ConditionalBranchFinished,
  type ConditionalBranchObserver,
  type ConditionalBranchStarted,
} from "../../../domain/executors/conditional-node-executor.js";
import {logReadableInfo} from "./structured-logger.js";

export const conditionalBranchLogger: ConditionalBranchObserver = {
  started: logBranchStarted,
  finished: logBranchFinished,
};

function logBranchStarted(event: ConditionalBranchStarted): void {
  logReadableInfo([
    `[Zweig startet] ${event.branchLabel}`,
    `Bedingung: ${event.node.title} (${event.node.id})`,
    `Bausteine: ${event.nodeCount} | Kanten: ${event.edgeCount}`,
  ].join("\n"));
}

function logBranchFinished(event: ConditionalBranchFinished): void {
  logReadableInfo([
    `[Zweig beendet] ${event.branchLabel}`,
    `Bausteine ausgeführt: ${event.resultCount}`,
    `Ausgabe: ${event.outputLength} Zeichen`,
  ].join("\n"));
}
