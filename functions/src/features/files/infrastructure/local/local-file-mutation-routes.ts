import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {and, eq} from "drizzle-orm";
import {type FastifyReply} from "fastify";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {files} from "../../../../db/schema.js";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {FileChange, FileCopy, FileParams, TeamFileDto, VersionParams, fileFromRow} from "./local-file-schemas.js";
import {currentFilesQuery} from "./sqlite-file-queries.js";
import {fileTeamId} from "./sqlite-file-team.js";
import {type FileMutationFailure, type SQLiteTeamFileMutations} from "./sqlite-team-file-mutations.js";

export type FileMutationRoutesOptions = {
  database: RuntimeExecutor;
  mutations: Pick<SQLiteTeamFileMutations, "change" | "copy" | "restore">;
  notifier: {publish(topic: string): void};
};

const responses = {200: TeamFileDto, 201: TeamFileDto, 400: ErrorResponse, 404: ErrorResponse, 409: ErrorResponse};

const failures: Record<FileMutationFailure, {status: 400 | 404 | 409; error: string}> = {
  fileNotFound: {status: 404, error: "Datei nicht gefunden."},
  versionNotFound: {status: 404, error: "Dateiversion nicht gefunden."},
  folderNotFound: {status: 400, error: "Das Verzeichnis existiert nicht."},
  nameTaken: {status: 409, error: "In diesem Verzeichnis gibt es schon eine Datei mit diesem Namen."},
};

export const fileMutationRoutes: FastifyPluginAsyncTypebox<FileMutationRoutesOptions> = async (app, options) => {
  const {database, mutations, notifier} = options;

  app.patch("/v1/files/:fileId", {schema: {params: FileParams, body: FileChange, response: responses}}, async (request, reply) => {
    const {teamId} = request.workspace;
    const changed = await mutations.change(teamId, request.params.fileId, request.body);
    if (changed.isErr()) return failed(reply, changed.error);
    notifier.publish("files");
    return sendFile(reply, database, teamId, request.params.fileId, 200);
  });

  app.post("/v1/files/:fileId/copy", {schema: {params: FileParams, body: FileCopy, response: responses}}, async (request, reply) => {
    const {teamId} = request.workspace;
    const copied = await mutations.copy(teamId, request.params.fileId, request.body);
    if (copied.isErr()) return failed(reply, copied.error);
    notifier.publish("files");
    return sendFile(reply, database, teamId, copied.value.fileId, 201);
  });

  app.post("/v1/files/:fileId/versions/:versionId/restore", {
    schema: {params: VersionParams, body: Type.Optional(Type.Object({})), response: responses},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const {fileId, versionId} = request.params;
    const restored = await mutations.restore(teamId, fileId, versionId);
    if (restored.isErr()) return failed(reply, restored.error);
    notifier.publish("files");
    notifier.publish(`file-versions:${fileId}`);
    return sendFile(reply, database, teamId, fileId, 200);
  });
};

function failed(reply: FastifyReply, failure: FileMutationFailure): FastifyReply {
  const {status, error} = failures[failure];
  return reply.code(status).send({error});
}

async function sendFile(
  reply: FastifyReply, database: RuntimeExecutor, teamId: string, fileId: string, status: 200 | 201,
): Promise<FastifyReply> {
  const row = await currentFilesQuery(database).where(and(eq(fileTeamId, teamId), eq(files.id, fileId))).get();
  return row === undefined ? reply.code(404).send(failures.fileNotFound) : reply.code(status).send(fileFromRow(row));
}
