import {type TaskDefinition} from "../task-definition.js";

export interface TaskStore {
  loadTask(teamId: string, taskId: string): Promise<TaskDefinition>;
}
