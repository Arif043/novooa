import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {activities, taskRuns, type NewActivities} from "../../../../db/schema.js";

export class ActivityRunMismatchError extends Error {
  constructor() {
    super("Die Ausführung existiert nicht oder gehört nicht zur angegebenen Aufgabe und zum Team.");
  }
}

export async function writeActivity(
  database: RuntimeExecutor, teamId: string, taskId: string, activity: NewActivities,
): Promise<void> {
  await database.transaction(async (tx) => {
    const run = await tx.select({id: taskRuns.id}).from(taskRuns).where(and(
      eq(taskRuns.id, activity.run_id), eq(taskRuns.team_id, teamId), eq(taskRuns.task_id, taskId))).get();
    if (run === undefined) throw new ActivityRunMismatchError();
    await tx.insert(activities).values(activity);
  });
}
