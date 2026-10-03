import {type NodeExecutionFailure} from "../entities/node-execution-failure.js";
import {type ActivityStore} from "../repositories/activity-store.js";
import {type TaskRunDocument} from "../repositories/task-run-store.js";

/** Hält die Bausteine eines gescheiterten Laufs in der Reihenfolge des Plans fest: erst die erfolgreichen, dann den gescheiterten. */
export async function recordNodeExecutionFailure(
  activityStore: ActivityStore,
  teamId: string,
  run: TaskRunDocument,
  failure?: NodeExecutionFailure,
): Promise<void> {
  if (!failure) return;
  await activityStore.writeNodeActivities(teamId, run, failure.completedNodeResults);
  await activityStore.writeFailedNodeActivity(teamId, run, failure.failedNode);
}
