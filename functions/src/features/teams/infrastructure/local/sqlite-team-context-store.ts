import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {type TeamContextStore} from "../../domain/repositories/team-context-store.js";

type TeamMembershipRow = SqlRow & {team_id: string};

export class SQLiteTeamContextStore implements TeamContextStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async currentTeamIdForUid(uid: string): Promise<string> {
    const membership = await this.database.get<TeamMembershipRow>(
      membershipSql,
      [uid],
    );
    if (!membership) throw new Error("Lokaler Arbeitsbereich fehlt.");
    return membership.team_id;
  }
}

const membershipSql = `SELECT team_id
  FROM team_members
  WHERE uid = ?
  ORDER BY created_at
  LIMIT 1`;
