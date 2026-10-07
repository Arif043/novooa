import {and, eq, getTableColumns, inArray} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {tasks, taskTriggers} from "../../../../db/schema.js";

export function triggerQuery(database: RuntimeExecutor) {
  return database.select({...getTableColumns(taskTriggers), team_id: tasks.team_id, task_title: tasks.title})
    .from(taskTriggers).innerJoin(tasks, eq(tasks.id, taskTriggers.task_id));
}

export function triggerMatching(database: RuntimeExecutor, teamId: string, triggerId: string) {
  const teamTasks = database.select({id: tasks.id}).from(tasks).where(eq(tasks.team_id, teamId));
  return and(eq(taskTriggers.id, triggerId), inArray(taskTriggers.task_id, teamTasks));
}
