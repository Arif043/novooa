import {LoginName} from "../entities/login-name.js";
import {
  displayNameFrom,
  type RuntimeRole,
  type RuntimeUser,
  type RuntimeUserChanges,
} from "../entities/runtime-user.js";
import {RuntimeUserError} from "../entities/runtime-user-error.js";
import {type InvitationRepository, type IssuedInvitation} from "../repositories/invitation-repository.js";
import {type PasswordCredentialRepository} from "../repositories/password-credential-repository.js";
import {type RuntimeSessionAccess} from "../repositories/runtime-session-access.js";
import {type RuntimeUserLimit} from "../repositories/runtime-user-limit.js";
import {type RuntimeUserRepository} from "../repositories/runtime-user-repository.js";

export type NewUserInput = {loginName: string; displayName: string; role: RuntimeRole};
export type CreatedUser = {user: RuntimeUser; invitation: IssuedInvitation};
export type UserOverview = {users: RuntimeUser[]; maxUsers: number | null};

export class ListUsers {
  constructor(private readonly users: RuntimeUserRepository, private readonly limit: RuntimeUserLimit) {}

  async execute(): Promise<UserOverview> {
    return {users: await this.users.list(), maxUsers: this.limit.maxUsers()};
  }
}

/** Legt ein Konto an und liefert den Einladungscode, mit dem die Person ihr Passwort setzt. */
export class CreateUser {
  constructor(
    private readonly users: RuntimeUserRepository,
    private readonly invitations: InvitationRepository,
    private readonly limit: RuntimeUserLimit,
  ) {}

  async execute(input: NewUserInput): Promise<CreatedUser> {
    const loginName = LoginName.from(input.loginName);
    const displayName = displayNameFrom(input.displayName);
    await this.ensureSeatFree();
    if (await this.users.findByLoginName(loginName) !== null) {
      throw new RuntimeUserError("login_name_taken", `Der Anmeldename „${loginName.value}“ ist schon vergeben.`);
    }
    const user = await this.users.create({loginName, displayName, role: input.role});
    return {user, invitation: await this.invitations.issue(user.uid)};
  }

  private async ensureSeatFree(): Promise<void> {
    const maxUsers = this.limit.maxUsers();
    if (maxUsers !== null && (await this.users.list()).length >= maxUsers) {
      throw new RuntimeUserError("user_limit_reached", `Die Lizenz erlaubt höchstens ${maxUsers} Benutzer.`);
    }
  }
}

/** Name oder Rolle ändern; der letzte Admin bleibt Admin. */
export class UpdateUser {
  constructor(private readonly users: RuntimeUserRepository) {}

  async execute(uid: string, changes: RuntimeUserChanges): Promise<RuntimeUser> {
    const user = await existingUser(this.users, uid);
    if (changes.role === "member" && user.role === "admin") await ensureAnotherAdmin(this.users, uid);
    const displayName = changes.displayName === undefined ? undefined : displayNameFrom(changes.displayName);
    const updated = await this.users.update(uid, {displayName, role: changes.role});
    if (updated === null) throw notFound();
    return updated;
  }
}

/** Passwort zurücksetzen: Das alte gilt nicht mehr, alle Sitzungen enden, ein neuer Code wird ausgegeben. */
export class ResetUserPassword {
  constructor(
    private readonly users: RuntimeUserRepository,
    private readonly passwords: PasswordCredentialRepository,
    private readonly invitations: InvitationRepository,
    private readonly sessions: RuntimeSessionAccess,
  ) {}

  async execute(actorUid: string, uid: string): Promise<IssuedInvitation> {
    ensureOtherAccount(actorUid, uid);
    await existingUser(this.users, uid);
    await this.passwords.remove(uid);
    await this.sessions.revokeSessionsOf(uid);
    return this.invitations.issue(uid);
  }
}

/** Konto löschen; seine Sitzungen enden sofort. Inhalte bleiben im Arbeitsbereich. */
export class DeleteUser {
  constructor(private readonly users: RuntimeUserRepository, private readonly sessions: RuntimeSessionAccess) {}

  async execute(actorUid: string, uid: string): Promise<void> {
    ensureOtherAccount(actorUid, uid);
    const user = await existingUser(this.users, uid);
    if (uid === this.users.workspaceOwnerUid()) {
      throw new RuntimeUserError("workspace_owner", "Das Konto aus der Einrichtung lässt sich nicht löschen.");
    }
    if (user.role === "admin") await ensureAnotherAdmin(this.users, uid);
    await this.sessions.revokeSessionsOf(uid);
    await this.users.delete(uid);
  }
}

async function existingUser(users: RuntimeUserRepository, uid: string): Promise<RuntimeUser> {
  const user = await users.find(uid);
  if (user === null) throw notFound();
  return user;
}

async function ensureAnotherAdmin(users: RuntimeUserRepository, uid: string): Promise<void> {
  const otherAdmins = (await users.list()).filter((user) => user.role === "admin" && user.uid !== uid);
  if (otherAdmins.length === 0) {
    throw new RuntimeUserError("last_admin", "Es muss immer mindestens einen Admin geben.");
  }
}

function ensureOtherAccount(actorUid: string, uid: string): void {
  if (actorUid === uid) {
    throw new RuntimeUserError("own_account", "Für das eigene Konto geht das hier nicht.");
  }
}

function notFound(): RuntimeUserError {
  return new RuntimeUserError("user_not_found", "Den Benutzer gibt es nicht.");
}
