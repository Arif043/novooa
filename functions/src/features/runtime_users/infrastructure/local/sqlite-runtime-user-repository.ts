import {and, eq, isNotNull, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {runtimePasswordCredentials, teamMembers, userProfiles} from "../../../../db/schema.js";
import {type LoginName} from "../../domain/entities/login-name.js";
import {
  isRuntimeRole,
  type NewRuntimeUser,
  type RuntimeUser,
  type RuntimeUserChanges,
} from "../../domain/entities/runtime-user.js";
import {type RuntimeUserRepository} from "../../domain/repositories/runtime-user-repository.js";

/** Der aktive Arbeitsbereich: sein Team und das Profil, dem er gehört. */
export type RuntimeUserWorkspace = {teamId: string; ownerUid: string};

/** Konten sind Profile mit Anmeldename und Mitgliedschaft im Team des aktiven Arbeitsbereichs. */
export class SQLiteRuntimeUserRepository implements RuntimeUserRepository {
  constructor(private readonly database: RuntimeExecutor, private readonly workspace: () => RuntimeUserWorkspace) {}

  async list(): Promise<RuntimeUser[]> {
    const rows = await this.accounts().orderBy(userProfiles.login_name);
    return rows.map(userFromRow);
  }

  async find(uid: string): Promise<RuntimeUser | null> {
    const row = await this.accounts(eq(userProfiles.uid, uid)).get();
    return row === undefined ? null : userFromRow(row);
  }

  async findByLoginName(loginName: LoginName): Promise<RuntimeUser | null> {
    const row = await this.accounts(eq(userProfiles.login_name, loginName.value)).get();
    return row === undefined ? null : userFromRow(row);
  }

  async create({loginName, displayName, role}: NewRuntimeUser): Promise<RuntimeUser> {
    const uid = randomUUID();
    await this.database.transaction(async (tx) => {
      await tx.insert(userProfiles).values({uid, login_name: loginName.value, display_name: displayName});
      await tx.insert(teamMembers).values({team_id: this.workspace().teamId, uid, role});
    });
    return (await this.find(uid))!;
  }

  async claimWorkspaceOwner({loginName, displayName}: Omit<NewRuntimeUser, "role">): Promise<RuntimeUser> {
    const {teamId, ownerUid} = this.workspace();
    await this.database.transaction(async (tx) => {
      await tx.update(userProfiles).set({login_name: loginName.value, display_name: displayName, updated_at: sql`CURRENT_TIMESTAMP`})
        .where(eq(userProfiles.uid, ownerUid));
      await tx.insert(teamMembers).values({team_id: teamId, uid: ownerUid, role: "admin"})
        .onConflictDoUpdate({target: [teamMembers.team_id, teamMembers.uid], set: {role: "admin"}});
    });
    return (await this.find(ownerUid))!;
  }

  workspaceOwnerUid(): string {
    return this.workspace().ownerUid;
  }

  async update(uid: string, {displayName, role}: RuntimeUserChanges): Promise<RuntimeUser | null> {
    const {teamId} = this.workspace();
    await this.database.transaction(async (tx) => {
      if (displayName !== undefined) {
        await tx.update(userProfiles).set({display_name: displayName, updated_at: sql`CURRENT_TIMESTAMP`})
          .where(eq(userProfiles.uid, uid));
      }
      if (role !== undefined) {
        await tx.update(teamMembers).set({role, updated_at: sql`CURRENT_TIMESTAMP`})
          .where(and(eq(teamMembers.team_id, teamId), eq(teamMembers.uid, uid)));
      }
    });
    return this.find(uid);
  }

  /** Löscht das Profil; Mitgliedschaft, Passwort, Einladungen und Sitzungen fallen per Fremdschlüssel weg. */
  async delete(uid: string): Promise<boolean> {
    if (await this.find(uid) === null) return false;
    await this.database.delete(userProfiles).where(eq(userProfiles.uid, uid));
    return true;
  }

  private accounts(condition?: ReturnType<typeof eq>) {
    return this.database.select({
      uid: userProfiles.uid, loginName: userProfiles.login_name, displayName: userProfiles.display_name,
      role: teamMembers.role, createdAt: userProfiles.created_at, passwordUid: runtimePasswordCredentials.uid,
    }).from(userProfiles)
      .innerJoin(teamMembers, eq(teamMembers.uid, userProfiles.uid))
      .leftJoin(runtimePasswordCredentials, eq(runtimePasswordCredentials.uid, userProfiles.uid))
      .where(and(eq(teamMembers.team_id, this.workspace().teamId), isNotNull(userProfiles.login_name), condition))
      .$dynamic();
  }
}

type AccountRow = {
  uid: string; loginName: string | null; displayName: string; role: string; createdAt: string; passwordUid: string | null;
};

function userFromRow(row: AccountRow): RuntimeUser {
  return {
    uid: row.uid, loginName: row.loginName ?? "", displayName: row.displayName,
    role: isRuntimeRole(row.role) ? row.role : "member", hasPassword: row.passwordUid !== null,
    createdAt: row.createdAt.includes("T") ? row.createdAt : `${row.createdAt.replace(" ", "T")}Z`,
  };
}
