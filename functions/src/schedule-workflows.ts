import {onSchedule} from "firebase-functions/v2/scheduler";
import {runDueTaskTriggers} from "./schedule/due-task-trigger-runner.js";

export const runDueTaskTriggersWorker = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Europe/Berlin",
    maxInstances: 1,
  },
  async () => runDueTaskTriggers(),
);
