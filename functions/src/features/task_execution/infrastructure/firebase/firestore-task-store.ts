import {UserFacingError} from "genkit";
import {type TaskDefinition} from "../../domain/entities/task.js";
import {taskDefinitionSchema} from "../genkit/runner/task-definition.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {type TaskStore} from "../../domain/repositories/task-store.js";

type TaskDocument = Record<string, unknown>;

export class FirestoreTaskStore implements TaskStore {
  async loadTask(teamId: string, taskId: string): Promise<TaskDefinition> {
    const snapshot = await getDatabase()
      .collection("teams")
      .doc(teamId)
      .collection("tasks")
      .doc(taskId)
      .get();
    if (!snapshot.exists) throw taskNotFound();
    return taskDefinitionFromDocument(snapshot.id, snapshot.data() ?? {});
  }
}

function taskNotFound(): UserFacingError {
  return new UserFacingError("NOT_FOUND", "Aufgabe wurde nicht gefunden.");
}

/** Exportiert für Tests; liest ein Firestore-Dokument als ausführbare Aufgabe. */
export function taskDefinitionFromDocument(
  documentId: string,
  data: TaskDocument,
): TaskDefinition {
  const graph = graphFromDocument(data["graph"]);
  return taskDefinitionSchema.parse({
    id: stringFrom(data["id"], documentId),
    title: stringFrom(data["title"], "Unbenannte Aufgabe"),
    objective: stringFrom(data["objective"], ""),
    nodes: graph.nodes,
    edges: graph.edges,
  });
}

function graphFromDocument(value: unknown): TaskDocument {
  const graph = objectFrom(value);
  return {
    nodes: objectListFrom(graph["nodes"]).map(nodeFromDocument),
    edges: objectListFrom(graph["edges"]).map(edgeFromDocument),
  };
}

function nodeFromDocument(data: TaskDocument): TaskDocument {
  const config = configFromDocument(data["config"]);
  return {
    id: stringFrom(data["id"], ""),
    primitive: stringFrom(config["primitive"], "stringInput"),
    title: stringFrom(data["title"], "Baustein"),
    description: stringFrom(data["description"], ""),
    outputs: outputsFrom(data["outputs"]),
    config,
  };
}

function configFromDocument(value: unknown): TaskDocument {
  const config = objectFrom(value);
  const primitive = primitiveFromDocument(config["primitive"]);
  if (primitive !== "conditionalFlow") return {...config, primitive};
  return {
    ...config,
    primitive,
    branches: objectListFrom(config["branches"]).map(branchFromDocument),
  };
}

function branchFromDocument(data: TaskDocument): TaskDocument {
  return {
    id: stringFrom(data["id"], ""),
    label: stringFrom(data["label"], ""),
    nodeIds: stringListFrom(data["nodeIds"]),
    graph: graphFromDocument(data["graph"]),
  };
}

function edgeFromDocument(data: TaskDocument): TaskDocument {
  const edge: TaskDocument = {
    from: stringFrom(data["from"], ""),
    to: stringFrom(data["to"], ""),
  };
  const conditionLabel = data["conditionLabel"];
  if (typeof conditionLabel === "string") edge.conditionLabel = conditionLabel;
  return edge;
}

function primitiveFromDocument(value: unknown): string {
  if (value === "conditional") return "conditionalFlow";
  if (typeof value === "string" && value.trim().length > 0) return value;
  return "stringInput";
}

function stringFrom(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}

/** Nur vollständige Einträge; ein kaputter Eintrag soll den Lauf nicht abbrechen. */
function outputsFrom(value: unknown): TaskDocument[] {
  return objectListFrom(value)
    .filter((output) => typeof output["key"] === "string" && typeof output["name"] === "string")
    .map((output) => ({
      key: output["key"],
      name: output["name"],
      showOnCanvas: output["showOnCanvas"] === true,
    }));
}

function stringListFrom(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

function objectListFrom(value: unknown): TaskDocument[] {
  if (!Array.isArray(value)) return [];
  return value.filter(isObject);
}

function objectFrom(value: unknown): TaskDocument {
  if (isObject(value)) return value;
  return {};
}

function isObject(value: unknown): value is TaskDocument {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
