import { type FastifyInstance, type FastifyReply } from "fastify";
import { randomUUID } from "node:crypto";
import { type LocalSqlDatabase, type SqlRow } from "../../../../shared/local/local-sql-database.js";
import { type LocalRuntimeRealtimeNotifier } from "../../../../shared/local/local-runtime-realtime-notifier.js";
type NoteRow = SqlRow & {
  content: string;
  id: string;
  knowledge_base_id: string;
  outgoing_links_json: string;
  path: string;
  title: string;
  updated_at: string;
};
export class LocalKnowledgeNoteHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalKnowledgeNoteHttpHandler): void {
    http.get("/v1/knowledge-notes", (request, reply) => current().list(reply));
    http.post("/v1/knowledge-notes", (request, reply) => current().create(request.body, reply));
    http.put<{
      Params: {
        noteId: string;
      };
    }>("/v1/knowledge-notes/:noteId", (request, reply) => current().update(request.params.noteId, request.body, reply));
    http.delete<{
      Params: {
        noteId: string;
      };
    }>("/v1/knowledge-notes/:noteId", (request, reply) => current().delete(request.params.noteId, reply));
  }
  constructor(private readonly database: LocalSqlDatabase, private readonly teamId: string, private readonly notifier: LocalRuntimeRealtimeNotifier) { }
  private async list(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.all<NoteRow>(listSql(), [this.teamId]);
    return reply.code(200).send({ items: rows.map(noteFromRow) });
  }
  private async create(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const note = noteFromRequest(body);
      const id = randomUUID();
      await this.database.run(insertSql(), [
        id, this.teamId, note.knowledgeBaseId, note.title, note.path,
        note.content, JSON.stringify(note.outgoingLinks),
      ]);
      this.notifier.publish("knowledge-notes");
      return this.byId(id, 201, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async update(id: string, body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const note = noteFromRequest(body);
      await this.database.run(updateSql(), [
        note.title, note.path, note.content, JSON.stringify(note.outgoingLinks),
        this.teamId, id,
      ]);
      this.notifier.publish("knowledge-notes");
      return this.byId(id, 200, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async delete(id: string, reply: FastifyReply): Promise<FastifyReply> {
    await this.database.run("DELETE FROM knowledge_notes WHERE team_id = ? AND id = ?", [this.teamId, id]);
    this.notifier.publish("knowledge-notes");
    return reply.code(204).send();
  }
  private async byId(id: string, statusCode: number, reply: FastifyReply): Promise<FastifyReply> {
    const row = await this.database.get<NoteRow>(byIdSql(), [this.teamId, id]);
    if (row === null)
      return reply.code(404).send({ error: "Notiz nicht gefunden." });
    return reply.code(statusCode).send(noteFromRow(row));
  }
}
function listSql(): string {
  return `SELECT id, knowledge_base_id, title, path, content, outgoing_links_json, updated_at
 FROM knowledge_notes WHERE team_id = ? ORDER BY title COLLATE NOCASE`;
}
function byIdSql(): string {
  return `SELECT id, knowledge_base_id, title, path, content, outgoing_links_json, updated_at
 FROM knowledge_notes WHERE team_id = ? AND id = ?`;
}
function insertSql(): string {
  return `INSERT INTO knowledge_notes(id, team_id, knowledge_base_id, title, path, content, outgoing_links_json)
 VALUES (?, ?, ?, ?, ?, ?, ?)`;
}
function updateSql(): string {
  return `UPDATE knowledge_notes SET title = ?, path = ?, content = ?, outgoing_links_json = ?,
 updated_at = CURRENT_TIMESTAMP WHERE team_id = ? AND id = ?`;
}
function noteFromRow(row: NoteRow): Record<string, unknown> {
  return {
    id: row.id, knowledgeBaseId: row.knowledge_base_id, title: row.title,
    path: row.path, content: row.content, outgoingLinks: stringList(row.outgoing_links_json),
    updatedAt: isoTimestamp(row.updated_at),
  };
}
function noteFromRequest(value: unknown): NoteInput {
  const input = recordFrom(value);
  const title = stringFrom(input.title, "title").trim();
  if (!title)
    throw new LocalKnowledgeNoteError("title muss ein nicht leerer String sein.");
  return {
    knowledgeBaseId: optionalString(input.knowledgeBaseId) || "default",
    title, path: optionalString(input.path), content: optionalString(input.content),
    outgoingLinks: stringListValue(input.outgoingLinks),
  };
}
function recordFrom(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalKnowledgeNoteError("Die lokale Notiz erwartet ein Objekt.");
}
function stringFrom(value: unknown, name: string): string {
  if (typeof value === "string")
    return value;
  throw new LocalKnowledgeNoteError(`${name} muss ein String sein.`);
}
function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}
function stringListValue(value: unknown): string[] {
  if (!Array.isArray(value) || !value.every((item) => typeof item === "string")) {
    throw new LocalKnowledgeNoteError("outgoingLinks muss eine String-Liste sein.");
  }
  return value;
}
function stringList(value: string): string[] {
  try {
    const parsed: unknown = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.filter((item): item is string => typeof item === "string") : [];
  }
  catch {
    return [];
  }
}
function isoTimestamp(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}
function invalidResponse(error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof LocalKnowledgeNoteError)
    return reply.code(400).send({ error: error.message });
  throw error;
}
type NoteInput = {
  content: string;
  knowledgeBaseId: string;
  outgoingLinks: string[];
  path: string;
  title: string;
};
class LocalKnowledgeNoteError extends Error {
}
