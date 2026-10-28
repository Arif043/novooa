import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {taskRuns} from "../../../../db/schema.js";
import {ErrorResponse, JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";
import {graphSnapshotFrom} from "./run-graph-snapshot.js";

export type TaskRunGraphRoutesOptions = {database: RuntimeExecutor};

/** Der Graph eines Laufs, wie er beim Start war — Grundlage der Ergebnisansicht. */
export const taskRunGraphRoutes: FastifyPluginAsyncTypebox<TaskRunGraphRoutesOptions> = async (app, {database}) => {
  app.get("/v1/task-runs/:runId/graph", {
    schema: {params: Type.Object({runId: NonEmptyString({maxLength: 200})}), response: {200: JsonObject, 404: ErrorResponse}},
  }, async (request, reply) => {
    const row = await database.select({graph: taskRuns.graph_snapshot_json}).from(taskRuns)
      .where(and(eq(taskRuns.team_id, request.workspace.teamId), eq(taskRuns.id, request.params.runId))).get();
    if (row === undefined) return reply.code(404).send({error: "Lauf nicht gefunden."});
    const snapshot = graphSnapshotFrom(row.graph);
    if (snapshot === undefined) return reply.code(404).send({error: "Für diesen Lauf gibt es keinen Graphen."});
    return snapshot;
  });
};
