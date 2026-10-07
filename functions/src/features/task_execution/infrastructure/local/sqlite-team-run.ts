import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {taskRuns} from "../../../../db/schema.js";

export function teamRunId(database: RuntimeExecutor, teamId: string, runId: string) {
  return database.select({id: taskRuns.id}).from(taskRuns)
    .where(and(eq(taskRuns.id, runId), eq(taskRuns.team_id, teamId)));
}

export async function requireTeamRun(database: RuntimeExecutor, teamId: string, runId: string): Promise<void> {
  if (await teamRunId(database, teamId, runId).get() === undefined) {
    throw new Error("Die Ausführung gehört nicht zum angegebenen Team oder existiert nicht.");
  }
}
