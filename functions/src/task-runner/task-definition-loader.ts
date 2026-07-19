import {UserFacingError} from "genkit";
import {type TaskDefinition} from "./task-definition.js";
import {type TaskStore} from "../domain/repositories/task-store.js";
import {type TeamContextStore} from "../domain/repositories/team-context-store.js";

type FirebaseAuthContext = {
  auth?: {
    uid?: string;
  };
};

type TaskDefinitionLoaderStores = {
  taskStore: TaskStore;
  teamContextStore: TeamContextStore;
};

export async function loadTaskDefinition(
  taskId: string,
  context: unknown,
  stores: TaskDefinitionLoaderStores,
): Promise<TaskDefinition> {
  const uid = uidFromContext(context);
  const teamId = await stores.teamContextStore.currentTeamIdForUid(uid);
  return stores.taskStore.loadTask(teamId, taskId);
}

export async function loadTaskDefinitionForTeam(
  teamId: string,
  taskId: string,
  taskStore: TaskStore,
): Promise<TaskDefinition> {
  return taskStore.loadTask(teamId, taskId);
}

function uidFromContext(context: unknown): string {
  const auth = (context as FirebaseAuthContext | undefined)?.auth;
  if (auth?.uid) return auth.uid;
  throw new UserFacingError("UNAUTHENTICATED", "Anmeldung ist erforderlich.");
}
