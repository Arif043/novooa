import {type TaskDefinition} from "../entities/task.js";

export interface TaskStore {
  loadTask(teamId: string, taskId: string): Promise<TaskDefinition>;
}
