import {UserFacingError} from "genkit";
import {currentTeamIdForUid} from "../team-context.js";
import {type TaskDefinition} from "./task-definition.js";
import {type TaskStore} from "../domain/repositories/task-store.js";
import {FirestoreTaskStore} from "../infrastructure/firebase/firestore-task-store.js";

type FirebaseAuthContext = {
  auth?: {
    uid?: string;
  };
};

const defaultTaskStore = new FirestoreTaskStore();

export async function loadTaskDefinition(
  taskId: string,
  context: unknown,
  taskStore: TaskStore = defaultTaskStore,
): Promise<TaskDefinition> {
  const uid = uidFromContext(context);
  const teamId = await currentTeamIdForUid(uid);
  return taskStore.loadTask(teamId, taskId);
}

export async function loadTaskDefinitionForTeam(
  teamId: string,
  taskId: string,
  taskStore: TaskStore = defaultTaskStore,
): Promise<TaskDefinition> {
  return taskStore.loadTask(teamId, taskId);
}

function uidFromContext(context: unknown): string {
  const auth = (context as FirebaseAuthContext | undefined)?.auth;
  if (auth?.uid) return auth.uid;
  throw new UserFacingError("UNAUTHENTICATED", "Anmeldung ist erforderlich.");
}
