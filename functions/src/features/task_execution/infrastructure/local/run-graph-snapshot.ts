import {type TaskDefinition} from "../../domain/entities/task.js";
import {taskDefinitionSchema} from "../genkit/runner/task-definition.js";

/** Die Aufgabe, wie sie beim Start war: Titel, Ziel, Knoten und Kanten. */
export function graphSnapshotJson(task: TaskDefinition | undefined): string | null {
  if (task === undefined) return null;
  const {id, title, objective, nodes, edges} = task;
  return JSON.stringify({id, title, objective, nodes, edges});
}

/**
 * `undefined` für Läufe von vor dem Schnappschuss und für Schnappschüsse, die das heutige Schema
 * nicht mehr liest — dann läuft der Lauf wie früher mit der gespeicherten Aufgabe.
 */
export function graphSnapshotFrom(value: string | null): TaskDefinition | undefined {
  if (value === null) return undefined;
  try {
    const parsed = taskDefinitionSchema.safeParse(JSON.parse(value));
    return parsed.success ? parsed.data : undefined;
  } catch {
    return undefined;
  }
}
