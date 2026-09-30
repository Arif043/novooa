import { type FastifyInstance, type FastifyReply } from "fastify";
import { type LocalSqlDatabase, type SqlRow } from "../../../../shared/local/local-sql-database.js";
type TaskRunRow = SqlRow & {
  created_at: string;
  error_json: string | null;
  final_output: string;
  id: string;
  interaction_json: string | null;
  review_output: string | null;
  status: string;
  task_id: string;
  task_title: string;
  updated_at: string;
  waiting_node_id: string | null;
};
type ActivityRow = SqlRow & {
  created_at: string;
  id: string;
  input: string;
  message: string;
  node_id: string | null;
  output: string;
  outputs_json: string;
  primitive: string | null;
  run_id: string;
  status: string;
  target: string;
  task_id: string;
  title: string;
};
export class LocalTaskActivityHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalTaskActivityHttpHandler): void {
    http.get("/v1/task-runs", (request, reply) => current().runs(reply));
    http.get("/v1/activities", (request, reply) => current().activities(reply));
    http.post("/v1/activities", (request, reply) => current().add(request.body, reply));
  }
  constructor(private readonly database: LocalSqlDatabase, private readonly teamId: string) { }
  private async runs(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.all<TaskRunRow>(runsSql(), [this.teamId]);
    return reply.code(200).send({ items: rows.map(runFromRow) });
  }
  private async activities(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.all<ActivityRow>(activitiesSql(), [this.teamId]);
    return reply.code(200).send({ items: rows.map(activityFromRow) });
  }
  private async add(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const activity = activityFromRequest(body);
      await this.database.run(insertActivitySql(), [
        activity.id, this.teamId, activity.runId, activity.taskId, activity.nodeId,
        activity.target, activity.primitive, activity.taskTitle, activity.status,
        activity.input, activity.output, JSON.stringify(activity.outputs), activity.message,
        activity.occurredAt,
      ]);
      return reply.code(201).send(activity);
    }
    catch (error) {
      if (error instanceof LocalActivityRequestError)
        return reply.code(400).send({ error: error.message });
      throw error;
    }
  }
}
function runsSql(): string {
  return `SELECT id, task_id, task_title, status, waiting_node_id, final_output,
 review_output, interaction_json, error_json, created_at, updated_at FROM task_runs
 WHERE team_id = ? ORDER BY updated_at DESC LIMIT 100`;
}
function activitiesSql(): string {
  return `SELECT id, run_id, task_id, node_id, target, primitive, title, status,
 input, output, outputs_json, message, created_at FROM activities
 WHERE team_id = ? ORDER BY created_at DESC LIMIT 100`;
}
function insertActivitySql(): string {
  return `INSERT INTO activities(id, team_id, run_id, task_id, node_id, target, primitive,
 title, status, input, output, outputs_json, message, created_at)
 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
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
