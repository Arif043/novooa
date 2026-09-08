import {type LocalSqlDatabase} from "./local-sql-database.js";

export type LocalRuntimeWorkspace = {
  teamId: string;
  teamName: string;
  userId: string;
};

export async function ensureLocalRuntimeWorkspace(
  database: LocalSqlDatabase,
  workspace: LocalRuntimeWorkspace,
): Promise<void> {
  await database.transaction(async () => {
    await database.run(insertTeamSql, [
      workspace.teamId, workspace.teamName, workspace.userId,
    ]);
    await database.run(insertMembershipSql, [
      workspace.teamId, workspace.userId, "Lokaler Benutzer", "owner",
    ]);
  });
}

const insertTeamSql = `INSERT OR IGNORE INTO teams(id, name, owner_uid)
  VALUES (?, ?, ?)`;

const insertMembershipSql = `INSERT OR IGNORE INTO team_members(
  team_id, uid, display_name, role
) VALUES (?, ?, ?, ?)`;
