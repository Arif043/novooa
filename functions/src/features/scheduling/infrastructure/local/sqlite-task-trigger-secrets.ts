import {and, eq, inArray} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {languageModelSecrets, tasks, taskTriggers} from "../../../../db/schema.js";
import {webhookSecretRef} from "../../domain/repositories/webhook-secret-store.js";

export async function deleteTaskTriggerSecrets(database: RuntimeExecutor, teamId: string, taskId: string): Promise<void> {
  const triggers = await database.select({id: taskTriggers.id})
    .from(taskTriggers).innerJoin(tasks, eq(tasks.id, taskTriggers.task_id))
    .where(and(eq(tasks.team_id, teamId), eq(tasks.id, taskId)));
  const secretRefs = triggers.map((trigger) => webhookSecretRef(teamId, trigger.id));
  if (secretRefs.length > 0) {
    await database.delete(languageModelSecrets).where(inArray(languageModelSecrets.secret_ref, secretRefs));
  }
}
