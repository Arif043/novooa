import {type FastifyPluginAsyncTypebox, type Static, Type} from "@fastify/type-provider-typebox";
import {and, eq, sql} from "drizzle-orm";
import {type FastifyReply} from "fastify";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {knowledgeNotes, type KnowledgeNotes} from "../../../../db/schema.js";
import {ErrorResponse, IdParams, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";

export type KnowledgeNoteRoutesOptions = {
  database: RuntimeExecutor;
  notifier: {publish(topic: string): void};
};

type NoteRow = Pick<KnowledgeNotes, "content" | "id" | "knowledge_base_id" | "outgoing_links_json" | "path" | "title" | "updated_at">;

const KnowledgeNote = Type.Object({
  id: Type.String(), knowledgeBaseId: Type.String(), title: Type.String(), path: Type.String(),
  content: Type.String(), outgoingLinks: Type.Array(Type.String()), updatedAt: Type.String(),
});
const NoteInput = Type.Object({
  title: Type.String({minLength: 1, pattern: "\\S"}),
  knowledgeBaseId: Type.Optional(Type.String()),
  path: Type.Optional(Type.String()),
  content: Type.Optional(Type.String()),
  outgoingLinks: Type.Array(Type.String()),
});
const NoteParams = IdParams("noteId");
const noteResponses = {200: KnowledgeNote, 201: KnowledgeNote, 404: ErrorResponse};
const noteColumns = {
  id: knowledgeNotes.id, knowledge_base_id: knowledgeNotes.knowledge_base_id, title: knowledgeNotes.title,
  path: knowledgeNotes.path, content: knowledgeNotes.content, outgoing_links_json: knowledgeNotes.outgoing_links_json,
  updated_at: knowledgeNotes.updated_at,
};

export const knowledgeNoteRoutes: FastifyPluginAsyncTypebox<KnowledgeNoteRoutesOptions> = async (app, {database, notifier}) => {
  app.get("/v1/knowledge-notes", {schema: {response: {200: ItemsOf(KnowledgeNote)}}}, async (request) => {
    const rows = await database.select(noteColumns).from(knowledgeNotes)
      .where(eq(knowledgeNotes.team_id, request.workspace.teamId)).orderBy(sql`${knowledgeNotes.title} COLLATE NOCASE`);
    return {items: rows.map(noteFromRow)};
  });

  app.post("/v1/knowledge-notes", {schema: {body: NoteInput, response: noteResponses}}, async (request, reply) => {
    const {teamId} = request.workspace;
    const note = noteFromBody(request.body);
    const id = randomUUID();
    await database.insert(knowledgeNotes).values({id, team_id: teamId, knowledge_base_id: note.knowledgeBaseId,
      title: note.title, path: note.path, content: note.content, outgoing_links_json: JSON.stringify(note.outgoingLinks)});
    notifier.publish("knowledge-notes");
    return noteById(database, teamId, id, 201, reply);
  });

  app.put("/v1/knowledge-notes/:noteId", {schema: {params: NoteParams, body: NoteInput, response: noteResponses}},
    async (request, reply) => {
      const {teamId} = request.workspace;
      const note = noteFromBody(request.body);
      await database.update(knowledgeNotes).set({title: note.title, path: note.path, content: note.content,
        outgoing_links_json: JSON.stringify(note.outgoingLinks), updated_at: sql`CURRENT_TIMESTAMP`})
        .where(and(eq(knowledgeNotes.team_id, teamId), eq(knowledgeNotes.id, request.params.noteId)));
      notifier.publish("knowledge-notes");
      return noteById(database, teamId, request.params.noteId, 200, reply);
    });

  app.delete("/v1/knowledge-notes/:noteId", {schema: {params: NoteParams}}, async (request, reply) => {
    await database.delete(knowledgeNotes)
      .where(and(eq(knowledgeNotes.team_id, request.workspace.teamId), eq(knowledgeNotes.id, request.params.noteId)));
    notifier.publish("knowledge-notes");
    return reply.code(204).send();
  });
};

function noteFromBody(body: Static<typeof NoteInput>) {
  return {
    knowledgeBaseId: body.knowledgeBaseId || "default", title: body.title.trim(),
    path: body.path ?? "", content: body.content ?? "", outgoingLinks: body.outgoingLinks,
  };
}

async function noteById(
  database: RuntimeExecutor, teamId: string, id: string, statusCode: 200 | 201, reply: FastifyReply,
): Promise<FastifyReply> {
  const row = await database.select(noteColumns).from(knowledgeNotes)
    .where(and(eq(knowledgeNotes.team_id, teamId), eq(knowledgeNotes.id, id))).get();
  return row === undefined
    ? reply.code(404).send({error: "Notiz nicht gefunden."})
    : reply.code(statusCode).send(noteFromRow(row));
}

function noteFromRow(row: NoteRow): Static<typeof KnowledgeNote> {
  return {
    id: row.id, knowledgeBaseId: row.knowledge_base_id, title: row.title, path: row.path, content: row.content,
    outgoingLinks: stringList(row.outgoing_links_json), updatedAt: isoTimestamp(row.updated_at),
  };
}

function stringList(value: string): string[] {
  try {
    const parsed: unknown = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.filter((item): item is string => typeof item === "string") : [];
  } catch {
    return [];
  }
}

function isoTimestamp(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}
