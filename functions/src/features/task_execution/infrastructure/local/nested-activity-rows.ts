import {type NewActivities} from "../../../../db/schema.js";
import {type FailedNode} from "../../domain/entities/node-execution-failure.js";
import {type NestedRun} from "../../domain/entities/nested-run.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";

/** Eine Aktivitätszeile ohne die Felder, die der Store vergibt (ID, Zeitstempel). */
export type ActivityRowDraft = Omit<NewActivities, "id" | "created_at">;

type Placement = {runId: string; parentNodeId?: string; iteration?: number};

/**
 * Ein Ergebnis als Zeilen: der Baustein selbst und, rekursiv, was in seinen Zweigen und
 * Schleifenrunden lief — jeweils mit umschließendem Baustein und Runde.
 */
export function resultRows(result: NodeExecutionResult, placement: Placement): ActivityRowDraft[] {
  return [{
    ...placed(placement), node_id: result.nodeId, primitive: result.primitive, title: result.nodeId,
    status: nodeStatus(result.status), input: "", output: "", outputs_json: JSON.stringify(result.outputs),
    message: result.message ?? "", console_json: JSON.stringify(result.console ?? {}),
    conversation_json: JSON.stringify(result.conversation ?? []), effects_json: JSON.stringify(result.effects ?? []),
    selected_branch_id: result.selectedBranchId ?? null, duration_ms: null,
  }, ...nestedRows(result.nodeId, result.nested, placement.runId)];
}

export function failedRows(failed: FailedNode, placement: Placement): ActivityRowDraft[] {
  return [{
    ...placed(placement), node_id: failed.nodeId, primitive: failed.primitive, title: failed.nodeId, status: "failed",
    input: "", output: "", outputs_json: "{}", message: failed.message, failure_code: failed.failureCode ?? null,
    failure_details_json: failed.failureDetails ? JSON.stringify(failed.failureDetails) : null,
    console_json: JSON.stringify(failed.console ?? {}), conversation_json: JSON.stringify(failed.conversation ?? []),
    effects_json: JSON.stringify(failed.effects ?? []), duration_ms: null,
  }, ...nestedRows(failed.nodeId, failed.nested, placement.runId)];
}

function nestedRows(parentNodeId: string, runs: readonly NestedRun[] | undefined, runId: string): ActivityRowDraft[] {
  return (runs ?? []).flatMap((run) => {
    const placement = {runId, parentNodeId, ...(run.iteration === undefined ? {} : {iteration: run.iteration})};
    return [
      ...run.results.flatMap((result) => resultRows(result, placement)),
      ...(run.failed ? failedRows(run.failed, placement) : []),
    ];
  });
}

function placed(placement: Placement): Pick<ActivityRowDraft, "run_id" | "target" | "parent_node_id" | "iteration"> {
  return {
    run_id: placement.runId, target: "node",
    parent_node_id: placement.parentNodeId ?? null, iteration: placement.iteration ?? null,
  };
}

function nodeStatus(status: NodeExecutionResult["status"]): string {
  if (status === "executed") return "succeeded";
  if (status === "waitingForApproval") return "waiting";
  return "skipped";
}
