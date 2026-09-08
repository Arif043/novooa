import {randomUUID} from "node:crypto";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

type NoteRow = SqlRow & {
  content: string;
  id: string;
  knowledge_base_id: string;
  outgoing_links_json: string;
  path: string;
  title: string;
  updated_at: string;
};

export class LocalKnowledgeNoteHttpHandler implements LocalRuntimeRequestHandler {
  constructor(private readonly database: LocalSqlDatabase, private readonly teamId: string) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    const path = pathFrom(request.url);
    if (request.method === "GET" && path === "/v1/knowledge-notes") return this.list();
    if (request.method === "POST" && path === "/v1/knowledge-notes") return this.create(request.body);
    const noteId = noteIdFrom(path);
    if (noteId === null) return null;
    if (request.method === "PUT") return this.update(noteId, request.body);
    if (request.method === "DELETE") return this.delete(noteId);
    return null;
  }

  private async list(): Promise<LocalRuntimeResponse> {
    const rows = await this.database.all<NoteRow>(listSql(), [this.teamId]);
    return {body: {items: rows.map(noteFromRow)}, statusCode: 200};
  }

  private async create(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const note = noteFromRequest(body);
      const id = randomUUID();
      await this.database.run(insertSql(), [
        id, this.teamId, note.knowledgeBaseId, note.title, note.path,
        note.content, JSON.stringify(note.outgoingLinks),
      ]);
      return this.byId(id, 201);
    } catch (error) {
      return invalidResponse(error);
    }
  }

  private async update(id: string, body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const note = noteFromRequest(body);
      await this.database.run(updateSql(), [
        note.title, note.path, note.content, JSON.stringify(note.outgoingLinks),
        this.teamId, id,
      ]);
      return this.byId(id, 200);
    } catch (error) {
      return invalidResponse(error);
    }
  }

  private async delete(id: string): Promise<LocalRuntimeResponse> {
    await this.database.run("DELETE FROM knowledge_notes WHERE team_id = ? AND id = ?", [this.teamId, id]);
    return {body: {}, statusCode: 204};
  }

  private async byId(id: string, statusCode: number): Promise<LocalRuntimeResponse> {
    const row = await this.database.get<NoteRow>(byIdSql(), [this.teamId, id]);
    if (row === null) return {body: {error: "Notiz nicht gefunden."}, statusCode: 404};
    return {body: noteFromRow(row), statusCode};
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
  if (!title) throw new LocalKnowledgeNoteError("title muss ein nicht leerer String sein.");
  return {
    knowledgeBaseId: optionalString(input.knowledgeBaseId) || "default",
    title, path: optionalString(input.path), content: optionalString(input.content),
    outgoingLinks: stringListValue(input.outgoingLinks),
  };
}

function pathFrom(url: string | undefined): string {
  return new URL(url ?? "/", "http://local-runtime").pathname;
}

function noteIdFrom(path: string): string | null {
  const match = /^\/v1\/knowledge-notes\/([^/]+)$/.exec(path);
  return match?.[1] ? decodeURIComponent(match[1]) : null;
}

function recordFrom(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalKnowledgeNoteError("Die lokale Notiz erwartet ein Objekt.");
}

function stringFrom(value: unknown, name: string): string {
  if (typeof value === "string") return value;
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
  } catch {
    return [];
  }
}

function isoTimestamp(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}

function invalidResponse(error: unknown): LocalRuntimeResponse {
  if (error instanceof LocalKnowledgeNoteError) return {body: {error: error.message}, statusCode: 400};
  throw error;
}

type NoteInput = {
  content: string;
  knowledgeBaseId: string;
  outgoingLinks: string[];
  path: string;
  title: string;
};

class LocalKnowledgeNoteError extends Error {}
