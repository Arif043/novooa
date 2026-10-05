import {and, eq, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {connections, type Connections} from "../../../../db/schema.js";
import {ConnectionNotFoundError, ConnectionRequestError, type Connection, type ConnectionAuth, type ConnectionInput} from "../../domain/entities/connection.js";
import {type ConnectionSecretStore} from "../../domain/repositories/connection-secret-store.js";
import {type ConnectionStore} from "../../domain/repositories/connection-store.js";

export class SQLiteConnectionStore implements ConnectionStore {
  constructor(private readonly database: RuntimeExecutor, private readonly secrets: ConnectionSecretStore) {}

  async list(teamId: string): Promise<Connection[]> {
    const rows = await this.database.select().from(connections).where(eq(connections.team_id, teamId))
      .orderBy(sql`${connections.name} COLLATE NOCASE`);
    return rows.map(connectionFromRow);
  }

  async find(teamId: string, connectionId: string): Promise<Connection | undefined> {
    const row = await this.rowOf(teamId, connectionId);
    return row === undefined ? undefined : connectionFromRow(row);
  }

  async create(teamId: string, input: ConnectionInput, secret: string): Promise<Connection> {
    const id = randomUUID();
    const secretRef = secretRefOf(teamId, id);
    const now = new Date().toISOString();
    await this.database.transaction(async (tx) => {
      await tx.insert(connections).values({id, team_id: teamId, name: input.name, base_url: input.baseUrl,
        auth_json: JSON.stringify(input.auth), secret_ref: secretRef, created_at: now, updated_at: now});
      await this.secrets.withDatabase(tx).write(secretRef, secret);
    });
    return (await this.find(teamId, id))!;
  }

  async update(teamId: string, connectionId: string, input: ConnectionInput, secret?: string): Promise<Connection> {
    const row = await this.rowOf(teamId, connectionId);
    if (row === undefined) throw new ConnectionNotFoundError(connectionId);
    if (secret === undefined && authFromJson(row.auth_json).kind !== input.auth.kind) {
      throw new ConnectionRequestError("Beim Wechsel der Anmeldeart ist ein neues Geheimnis nötig.");
    }
    await this.database.transaction(async (tx) => {
      await tx.update(connections).set({name: input.name, base_url: input.baseUrl, auth_json: JSON.stringify(input.auth),
        updated_at: new Date().toISOString()}).where(and(eq(connections.team_id, teamId), eq(connections.id, connectionId)));
      if (secret !== undefined) await this.secrets.withDatabase(tx).write(row.secret_ref, secret);
    });
    return (await this.find(teamId, connectionId))!;
  }

  async delete(teamId: string, connectionId: string): Promise<void> {
    const row = await this.rowOf(teamId, connectionId);
    if (row === undefined) return;
    await this.database.delete(connections).where(and(eq(connections.team_id, teamId), eq(connections.id, connectionId)));
    await this.secrets.delete(row.secret_ref);
  }

  async loadSecret(teamId: string, connectionId: string): Promise<string> {
    const row = await this.rowOf(teamId, connectionId);
    if (row === undefined) throw new ConnectionNotFoundError(connectionId);
    const secret = await this.secrets.read(row.secret_ref);
    if (secret === null) throw new ConnectionNotFoundError(connectionId);
    return secret;
  }

  private async rowOf(teamId: string, connectionId: string): Promise<Connections | undefined> {
    return this.database.select().from(connections)
      .where(and(eq(connections.team_id, teamId), eq(connections.id, connectionId))).get();
  }
}

export function secretRefOf(teamId: string, connectionId: string): string {
  return `connection/${teamId}/${connectionId}`;
}

function connectionFromRow(row: Connections): Connection {
  return {id: row.id, teamId: row.team_id, name: row.name, baseUrl: row.base_url, auth: authFromJson(row.auth_json), updatedAt: row.updated_at};
}

function authFromJson(json: string): ConnectionAuth {
  return JSON.parse(json) as ConnectionAuth;
}
