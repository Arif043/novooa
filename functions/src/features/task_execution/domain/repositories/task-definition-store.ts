import {type TaskDefinition} from "../entities/task.js";

export interface TaskDefinitionStore {
  delete(teamId: string, taskId: string): Promise<void>;
  list(teamId: string): Promise<TaskDefinition[]>;
  save(
    teamId: string,
    userId: string,
    definition: TaskDefinition,
    selectedNodeId: string,
  ): Promise<void>;
  selectedNodeId(teamId: string, taskId: string): Promise<string>;
}
