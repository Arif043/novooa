import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {and, asc, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {activities, taskRuns} from "../../../../db/schema.js";
import {ErrorResponse, ItemsOf, JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";
import {Activity} from "./local-task-activity-schemas.js";
import {activityRowsQuery} from "./sqlite-activity-query.js";
import {activityFromRow} from "./sqlite-task-activity-mapping.js";
import {graphSnapshotFrom} from "./run-graph-snapshot.js";

export type TaskRunGraphRoutesOptions = {database: RuntimeExecutor};

/** Der Graph eines Laufs, wie er beim Start war — Grundlage der Ergebnisansicht. */
const RunParams = Type.Object({runId: NonEmptyString({maxLength: 200})});

/** Obergrenze je Lauf: schützt vor riesigen Antworten bei sehr langen Schleifen. */
const maximumRunActivities = 10_000;

export const taskRunGraphRoutes: FastifyPluginAsyncTypebox<TaskRunGraphRoutesOptions> = async (app, {database}) => {
  /** Alle Bausteine eines Laufs in Reihenfolge, auch innerhalb von Zweigen und Schleifenrunden. */
  app.get("/v1/task-runs/:runId/activities", {
    schema: {params: RunParams, response: {200: ItemsOf(Activity)}},
  }, async (request) => {
    const rows = await activityRowsQuery(database).where(and(
      eq(taskRuns.team_id, request.workspace.teamId), eq(activities.run_id, request.params.runId), eq(activities.target, "node"),
    )).orderBy(asc(activities.created_at)).limit(maximumRunActivities);
    return {items: rows.map(activityFromRow)};
  });

  app.get("/v1/task-runs/:runId/graph", {
    schema: {params: RunParams, response: {200: JsonObject, 404: ErrorResponse}},
  }, async (request, reply) => {
    const row = await database.select({graph: taskRuns.graph_snapshot_json}).from(taskRuns)
      .where(and(eq(taskRuns.team_id, request.workspace.teamId), eq(taskRuns.id, request.params.runId))).get();
    if (row === undefined) return reply.code(404).send({error: "Lauf nicht gefunden."});
    const snapshot = graphSnapshotFrom(row.graph);
    if (snapshot === undefined) return reply.code(404).send({error: "Für diesen Lauf gibt es keinen Graphen."});
    return snapshot;
  });
};
