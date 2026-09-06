import {onSchedule} from "firebase-functions/v2/scheduler";
import {withExceptionLogging} from "../../../../shared/logging/logger.js";
import {runDueTaskTriggers} from "./due-task-trigger-runner.js";

export const runDueTaskTriggersWorker = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Europe/Berlin",
    maxInstances: 1,
  },
  async () => withExceptionLogging(
    "task_trigger.worker_failed",
    () => runDueTaskTriggers(),
  ),
);
