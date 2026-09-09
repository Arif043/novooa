import {type LocalSqlDatabase, type SqlRow} from "../local/local-sql-database.js";
import {
  type LocalApplicationLog,
  type LocalApplicationLogStore,
} from "./local-application-log-store.js";

type ApplicationLogRow = SqlRow & {
  created_at: string;
  data_json: string;
  event: string;
  id: string;
  level: "info" | "error";
  source: "client" | "runtime";
  message: string | null;
};

export class SQLiteLocalApplicationLogStore implements LocalApplicationLogStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async append(log: LocalApplicationLog): Promise<void> {
    await this.database.run(insertSql, [
      log.id, log.teamId, log.source, log.level, log.event, log.message,
      JSON.stringify(log.data), log.occurredAt,
    ]);
  }

  async recent(teamId: string, limit: number): Promise<LocalApplicationLog[]> {
    const rows = await this.database.all<ApplicationLogRow>(recentSql, [teamId, limit]);
    return rows.map((row) => logFrom(row, teamId));
  }
}

const insertSql = `INSERT INTO application_logs(
  id, team_id, source, level, event, message, data_json, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;

const recentSql = `SELECT id, source, level, event, message, data_json, created_at
  FROM application_logs WHERE team_id = ? ORDER BY created_at DESC, id DESC LIMIT ?`;

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
