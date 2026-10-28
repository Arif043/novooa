import {type FastifyPluginAsyncTypebox} from "@fastify/type-provider-typebox";
import {and, desc, eq, isNull} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {activities, taskRuns} from "../../../../db/schema.js";
import {ErrorResponse, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {Activity, NewActivity, TaskRun} from "./local-task-activity-schemas.js";
import {activityRowsQuery, taskRunRowsQuery} from "./sqlite-activity-query.js";
import {ActivityRunMismatchError, writeActivity} from "./sqlite-activity-write.js";
import {activityFromRow, runFromRow} from "./sqlite-task-activity-mapping.js";

export type TaskActivityRoutesOptions = {database: RuntimeExecutor};

export const taskActivityRoutes: FastifyPluginAsyncTypebox<TaskActivityRoutesOptions> = async (app, {database}) => {
  app.get("/v1/task-runs", {schema: {response: {200: ItemsOf(TaskRun)}}}, async (request) => {
    const rows = await taskRunRowsQuery(database).where(eq(taskRuns.team_id, request.workspace.teamId))
      .orderBy(desc(taskRuns.updated_at)).limit(100);
    return {items: rows.map(runFromRow)};
  });

  /** Die Historie zeigt nur die oberste Ebene; innere Bausteine stehen in der Ergebnisansicht. */
  app.get("/v1/activities", {schema: {response: {200: ItemsOf(Activity)}}}, async (request) => {
    const rows = await activityRowsQuery(database)
      .where(and(eq(taskRuns.team_id, request.workspace.teamId), isNull(activities.parent_node_id)))
      .orderBy(desc(activities.created_at)).limit(100);
    return {items: rows.map(activityFromRow)};
  });

  app.post("/v1/activities", {schema: {body: NewActivity, response: {201: Activity, 400: ErrorResponse}}}, async (request, reply) => {
    const activity = {...request.body, nodeId: request.body.nodeId ?? null, primitive: request.body.primitive ?? null,
      input: request.body.input ?? "", output: request.body.output ?? "", outputs: request.body.outputs ?? {},
      message: request.body.message ?? "", failureCode: null, failureDetails: null, console: {stdout: "", stderr: ""}, conversation: [], effects: [],
      parentNodeId: null, iteration: null, selectedBranchId: null,
      origin: {startedBy: null, reviewedBy: null, triggerType: null}};
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
