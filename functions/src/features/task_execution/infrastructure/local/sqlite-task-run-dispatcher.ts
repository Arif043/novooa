import {
  type TaskRunDispatcher,
  type TaskRunDispatchInput,
} from "../../domain/repositories/task-run-dispatcher.js";
import {SQLiteTaskRunJobStore} from "./sqlite-task-run-job-store.js";

export class SQLiteTaskRunDispatcher implements TaskRunDispatcher {
  constructor(private readonly jobStore: SQLiteTaskRunJobStore) {}

  async dispatchTaskRun(input: TaskRunDispatchInput): Promise<void> {
    await this.jobStore.enqueue(input);
  }
}
