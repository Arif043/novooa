import {
  type TaskRunDispatcher,
  type TaskRunDispatchInput,
} from "../../domain/repositories/task-run-dispatcher.js";
import {SQLiteTaskRunJobStore} from "./sqlite-task-run-job-store.js";

export interface TaskRunQueueNotifier {
  notify(): void;
}

export class SQLiteTaskRunDispatcher implements TaskRunDispatcher {
  constructor(
    private readonly jobStore: SQLiteTaskRunJobStore,
    private readonly queueNotifier: TaskRunQueueNotifier,
  ) {}

  async dispatchTaskRun(input: TaskRunDispatchInput): Promise<void> {
    await this.jobStore.enqueue(input);
    this.queueNotifier.notify();
  }
}
