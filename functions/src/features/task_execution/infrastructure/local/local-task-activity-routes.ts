import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {desc, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {activities, taskRuns} from "../../../../db/schema.js";
import {ErrorResponse, ItemsOf, JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";
import {ActivityRunMismatchError, writeActivity} from "./sqlite-activity-write.js";
import {activityFromRow, runFromRow} from "./local-task-activity-mapping.js";

export type TaskActivityRoutesOptions = {database: RuntimeExecutor};

const NullableString = Type.Union([Type.String(), Type.Null()]);
const TaskRun = Type.Object({
  runId: Type.String(), taskId: Type.String(), taskTitle: Type.String(), status: Type.String(),
  waitingNodeId: NullableString, finalOutput: Type.String(), reviewOutput: NullableString,
  interaction: Type.Unknown(), error: Type.Unknown(), createdAt: Type.String(), updatedAt: Type.String(),
});
const Activity = Type.Object({
  id: Type.String(), runId: Type.String(), taskId: Type.String(), taskTitle: Type.String(), target: Type.String(),
  status: Type.String(), occurredAt: Type.String(), nodeId: NullableString, primitive: NullableString,
  input: Type.String(), output: Type.String(), outputs: JsonObject, message: Type.String(),
  console: Type.Object({stdout: Type.String(), stderr: Type.String()}),
});
const NewActivity = Type.Object({
  id: NonEmptyString(), runId: NonEmptyString(), taskId: NonEmptyString(), taskTitle: NonEmptyString(),
  target: NonEmptyString(), status: NonEmptyString(), occurredAt: NonEmptyString(),
  nodeId: Type.Optional(NullableString), primitive: Type.Optional(NullableString),
  input: Type.Optional(Type.String()), output: Type.Optional(Type.String()),
  outputs: Type.Optional(JsonObject), message: Type.Optional(Type.String()),
});

export const taskActivityRoutes: FastifyPluginAsyncTypebox<TaskActivityRoutesOptions> = async (app, {database}) => {
  app.get("/v1/task-runs", {schema: {response: {200: ItemsOf(TaskRun)}}}, async (request) => {
    const rows = await database.select({id: taskRuns.id, task_id: taskRuns.task_id, task_title: taskRuns.task_title,
      status: taskRuns.status, waiting_node_id: taskRuns.waiting_node_id, final_output: taskRuns.final_output,
      review_output: taskRuns.review_output, interaction_json: taskRuns.interaction_json, error_json: taskRuns.error_json,
      created_at: taskRuns.created_at, updated_at: taskRuns.updated_at}).from(taskRuns)
      .where(eq(taskRuns.team_id, request.workspace.teamId)).orderBy(desc(taskRuns.updated_at)).limit(100);
    return {items: rows.map(runFromRow)};
  });

  app.get("/v1/activities", {schema: {response: {200: ItemsOf(Activity)}}}, async (request) => {
    const rows = await database.select({id: activities.id, run_id: activities.run_id, task_id: taskRuns.task_id,
      node_id: activities.node_id, target: activities.target, primitive: activities.primitive, title: activities.title,
      status: activities.status, input: activities.input, output: activities.output, outputs_json: activities.outputs_json,
      message: activities.message, console_json: activities.console_json, created_at: activities.created_at}).from(activities)
      .innerJoin(taskRuns, eq(taskRuns.id, activities.run_id))
      .where(eq(taskRuns.team_id, request.workspace.teamId)).orderBy(desc(activities.created_at)).limit(100);
    return {items: rows.map(activityFromRow)};
  });

  app.post("/v1/activities", {schema: {body: NewActivity, response: {201: Activity, 400: ErrorResponse}}}, async (request, reply) => {
    const activity = {...request.body, nodeId: request.body.nodeId ?? null, primitive: request.body.primitive ?? null,
      input: request.body.input ?? "", output: request.body.output ?? "", outputs: request.body.outputs ?? {},
      message: request.body.message ?? "", console: {stdout: "", stderr: ""}};
    try {
      await writeActivity(database, request.workspace.teamId, activity.taskId, {
        id: activity.id, run_id: activity.runId, node_id: activity.nodeId, target: activity.target,
        primitive: activity.primitive, title: activity.taskTitle, status: activity.status,
        input: activity.input, output: activity.output, outputs_json: JSON.stringify(activity.outputs),
        message: activity.message, created_at: activity.occurredAt});
    } catch (error) {
      if (error instanceof ActivityRunMismatchError) return reply.code(400).send({error: error.message});
      throw error;
    }
    return reply.code(201).send(activity);
  });
};
