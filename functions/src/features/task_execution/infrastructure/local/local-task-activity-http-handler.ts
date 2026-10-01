import {desc, eq} from "drizzle-orm";
import {type FastifyInstance, type FastifyReply} from "fastify";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {activities, taskRuns, type Activities, type TaskRuns} from "../../../../db/schema.js";
type TaskRunRow = Pick<TaskRuns, "created_at" | "error_json" | "final_output" | "id" | "interaction_json" | "review_output" | "status" | "task_id" | "task_title" | "updated_at" | "waiting_node_id">;
type ActivityRow = Pick<Activities, "created_at" | "id" | "input" | "message" | "node_id" | "output" | "outputs_json" | "primitive" | "run_id" | "status" | "target" | "task_id" | "title">;
export class LocalTaskActivityHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalTaskActivityHttpHandler): void {
    http.get("/v1/task-runs", (request, reply) => current().runs(reply));
    http.get("/v1/activities", (request, reply) => current().activities(reply));
    http.post("/v1/activities", (request, reply) => current().add(request.body, reply));
  }
  constructor(private readonly database: RuntimeExecutor, private readonly teamId: string) { }
  private async runs(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.select({id: taskRuns.id, task_id: taskRuns.task_id, task_title: taskRuns.task_title, status: taskRuns.status, waiting_node_id: taskRuns.waiting_node_id, final_output: taskRuns.final_output, review_output: taskRuns.review_output, interaction_json: taskRuns.interaction_json, error_json: taskRuns.error_json, created_at: taskRuns.created_at, updated_at: taskRuns.updated_at}).from(taskRuns).where(eq(taskRuns.team_id, this.teamId)).orderBy(desc(taskRuns.updated_at)).limit(100);
    return reply.code(200).send({ items: rows.map(runFromRow) });
  }
  private async activities(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.select({id: activities.id, run_id: activities.run_id, task_id: activities.task_id, node_id: activities.node_id, target: activities.target, primitive: activities.primitive, title: activities.title, status: activities.status, input: activities.input, output: activities.output, outputs_json: activities.outputs_json, message: activities.message, created_at: activities.created_at}).from(activities).where(eq(activities.team_id, this.teamId)).orderBy(desc(activities.created_at)).limit(100);
    return reply.code(200).send({ items: rows.map(activityFromRow) });
  }
  private async add(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const activity = activityFromRequest(body);
      await this.database.insert(activities).values({id: activity.id, team_id: this.teamId, run_id: activity.runId, task_id: activity.taskId, node_id: activity.nodeId, target: activity.target, primitive: activity.primitive, title: activity.taskTitle, status: activity.status, input: activity.input, output: activity.output, outputs_json: JSON.stringify(activity.outputs), message: activity.message, created_at: activity.occurredAt});
      return reply.code(201).send(activity);
    }
    catch (error) {
      if (error instanceof LocalActivityRequestError)
        return reply.code(400).send({ error: error.message });
      throw error;
    }
  }
}
function runFromRow(row: TaskRunRow): Record<string, unknown> {
  return {
    runId: row.id, taskId: row.task_id, taskTitle: row.task_title, status: row.status,
    waitingNodeId: row.waiting_node_id, finalOutput: row.final_output,
    reviewOutput: row.review_output, interaction: jsonValue(row.interaction_json),
    error: jsonValue(row.error_json), createdAt: isoTimestamp(row.created_at),
    updatedAt: isoTimestamp(row.updated_at),
  };
}
function activityFromRow(row: ActivityRow): Record<string, unknown> {
  return {
    id: row.id, runId: row.run_id, taskId: row.task_id, taskTitle: row.title,
    target: row.target, status: row.status, occurredAt: isoTimestamp(row.created_at),
    nodeId: row.node_id, primitive: row.primitive, input: row.input, output: row.output,
    outputs: jsonRecord(row.outputs_json), message: row.message,
  };
}
function activityFromRequest(value: unknown): LocalActivityDocument {
  const input = recordFrom(value, "Die lokale Aktivität erwartet ein Objekt.");
  return {
    id: requiredString(input.id, "id"), runId: requiredString(input.runId, "runId"),
    taskId: requiredString(input.taskId, "taskId"), taskTitle: requiredString(input.taskTitle, "taskTitle"),
    target: requiredString(input.target, "target"), status: requiredString(input.status, "status"),
    occurredAt: requiredString(input.occurredAt, "occurredAt"), nodeId: nullableString(input.nodeId),
    primitive: nullableString(input.primitive), input: optionalString(input.input),
    output: optionalString(input.output), outputs: recordFrom(input.outputs ?? {}, "outputs muss ein Objekt sein."),
    message: optionalString(input.message),
  };
}
function isoTimestamp(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}
function jsonValue(value: string | null): unknown {
  if (value === null)
    return null;
  try {
    return JSON.parse(value) as unknown;
  }
  catch {
    return null;
  }
}
function jsonRecord(value: string): Record<string, unknown> {
  const parsed = jsonValue(value);
  return parsed !== null && typeof parsed === "object" && !Array.isArray(parsed)
    ? parsed as Record<string, unknown> : {};
}
function recordFrom(value: unknown, message: string): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalActivityRequestError(message);
}
function requiredString(value: unknown, name: string): string {
  if (typeof value === "string" && value.trim().length > 0)
    return value;
  throw new LocalActivityRequestError(`${name} muss ein nicht leerer String sein.`);
}
function nullableString(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}
function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}
class LocalActivityRequestError extends Error {
}
type LocalActivityDocument = {
  id: string;
  input: string;
  message: string;
  nodeId: string | null;
  occurredAt: string;
  output: string;
  outputs: Record<string, unknown>;
  primitive: string | null;
  runId: string;
  status: string;
  target: string;
  taskId: string;
  taskTitle: string;
};
