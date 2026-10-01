import {eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {teamMembers} from "../../../../db/schema.js";
import {type TeamContextStore} from "../../domain/repositories/team-context-store.js";

export class SQLiteTeamContextStore implements TeamContextStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async currentTeamIdForUid(uid: string): Promise<string> {
    const membership = (await this.database.select({team_id: teamMembers.team_id}).from(teamMembers).where(eq(teamMembers.uid, uid)).orderBy(teamMembers.created_at).limit(1).get()) ?? null;
    if (!membership) throw new Error("Lokaler Arbeitsbereich fehlt.");
    return membership.team_id;
  }
}
