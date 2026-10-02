import {SQLiteFolderAncestry} from "../../../files/infrastructure/local/sqlite-folder-ancestry.js";
import {SQLiteTaskDefinitionStore} from "../../../task_execution/infrastructure/local/sqlite-task-definition-store.js";
import {SQLiteTaskTriggerStore} from "../../infrastructure/local/sqlite-task-trigger-store.js";
import {TriggerCycleGuard} from "./trigger-cycle-guard.js";
import {type RuntimeExecutor} from "../../../../db/database.js";

/** Nur Tests: ein Guard, der nie eingreift. */
export const permissiveCycleGuard = {
  checkTrigger: async () => ({blocked: null, warnings: []}),
  checkTask: async () => ({blocked: null, warnings: []}),
} as unknown as TriggerCycleGuard;

/** Nur Tests: der echte Guard über die SQLite-Speicher. */
export function cycleGuardFor(database: RuntimeExecutor): TriggerCycleGuard {
  return new TriggerCycleGuard({
    tasks: new SQLiteTaskDefinitionStore(database),
    triggers: new SQLiteTaskTriggerStore(database),
    folders: new SQLiteFolderAncestry(database),
  });
}
