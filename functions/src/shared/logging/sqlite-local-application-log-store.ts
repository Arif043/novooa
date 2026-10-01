import {desc, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../db/database.js";
import {applicationLogs, type ApplicationLogs} from "../../db/schema.js";
import {
  type LocalApplicationLog,
  type LocalApplicationLogStore,
} from "./local-application-log-store.js";

type ApplicationLogRow = Pick<ApplicationLogs, "created_at" | "data_json" | "event" | "id" | "level" | "source" | "message">;

export class SQLiteLocalApplicationLogStore implements LocalApplicationLogStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async append(log: LocalApplicationLog): Promise<void> {
    await this.database.insert(applicationLogs).values({id: log.id, team_id: log.teamId, source: log.source, level: log.level, event: log.event, message: log.message, data_json: JSON.stringify(log.data), created_at: log.occurredAt});
  }

  async recent(teamId: string, limit: number): Promise<LocalApplicationLog[]> {
    const rows = await this.database.select({id: applicationLogs.id, source: applicationLogs.source, level: applicationLogs.level, event: applicationLogs.event, message: applicationLogs.message, data_json: applicationLogs.data_json, created_at: applicationLogs.created_at}).from(applicationLogs).where(eq(applicationLogs.team_id, teamId)).orderBy(desc(applicationLogs.created_at), desc(applicationLogs.id)).limit(limit);
    return rows.map((row) => logFrom(row, teamId));
  }
}

function logFrom(row: ApplicationLogRow, teamId: string): LocalApplicationLog {
  return {
    id: row.id,
    teamId,
    source: row.source,
    level: row.level,
    event: row.event,
    message: row.message,
    data: dataFrom(row.data_json),
    occurredAt: timestampFrom(row.created_at),
  };
}

function dataFrom(value: string): Record<string, unknown> {
  try {
    const parsed: unknown = JSON.parse(value);
    return parsed !== null && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed as Record<string, unknown> : {};
  } catch {
    return {};
  }
}

function timestampFrom(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}
