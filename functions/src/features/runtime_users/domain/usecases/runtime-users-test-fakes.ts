import {type LoginName} from "../entities/login-name.js";
import {type RuntimePassword} from "../entities/runtime-password.js";
import {type NewRuntimeUser, type RuntimeUser, type RuntimeUserChanges} from "../entities/runtime-user.js";
import {type SessionDevice} from "../entities/session-device.js";
import {type InvitationRepository, type IssuedInvitation} from "../repositories/invitation-repository.js";
import {type PasswordCredentialRepository} from "../repositories/password-credential-repository.js";
import {type RuntimeSessionAccess} from "../repositories/runtime-session-access.js";
import {type RuntimeUserRepository} from "../repositories/runtime-user-repository.js";

/** Nur Tests: Konten im Speicher; `owner` ist das Profil des Arbeitsbereichs (noch ohne Anmeldename). */
export class MemoryUsers implements RuntimeUserRepository {
  readonly accounts = new Map<string, RuntimeUser>();
  private next = 1;

  async list(): Promise<RuntimeUser[]> {
    return [...this.accounts.values()];
  }

  async find(uid: string): Promise<RuntimeUser | null> {
    return this.accounts.get(uid) ?? null;
  }

  async findByLoginName(loginName: LoginName): Promise<RuntimeUser | null> {
    return [...this.accounts.values()].find((user) => user.loginName === loginName.value) ?? null;
  }

  async create({loginName, displayName, role}: NewRuntimeUser): Promise<RuntimeUser> {
    return this.put({uid: `user-${this.next++}`, loginName: loginName.value, displayName, role});
  }

  async claimWorkspaceOwner({loginName, displayName}: Omit<NewRuntimeUser, "role">): Promise<RuntimeUser> {
    return this.put({uid: "owner", loginName: loginName.value, displayName, role: "admin"});
  }

  workspaceOwnerUid(): string {
    return "owner";
  }

  async update(uid: string, changes: RuntimeUserChanges): Promise<RuntimeUser | null> {
    const user = this.accounts.get(uid);
    if (user === undefined) return null;
    const updated = {...user, displayName: changes.displayName ?? user.displayName, role: changes.role ?? user.role};
    this.accounts.set(uid, updated);
    return updated;
  }

  async delete(uid: string): Promise<boolean> {
    return this.accounts.delete(uid);
  }

  put(user: Pick<RuntimeUser, "uid" | "loginName" | "displayName" | "role">): RuntimeUser {
    const stored = {...user, hasPassword: false, createdAt: "2026-10-19T00:00:00.000Z"};
    this.accounts.set(user.uid, stored);
    return stored;
  }
}

export class MemoryPasswords implements PasswordCredentialRepository {
  readonly byUid = new Map<string, string>();

  async hasAny(): Promise<boolean> {
    return this.byUid.size > 0;
  }

  async verify(uid: string | null, password: string): Promise<boolean> {
    return uid !== null && this.byUid.get(uid) === password;
  }

  async set(uid: string, password: RuntimePassword): Promise<void> {
    this.byUid.set(uid, password.value);
  }

  async remove(uid: string): Promise<void> {
    this.byUid.delete(uid);
  }
}

export class MemoryInvitations implements InvitationRepository {
  readonly byCode = new Map<string, string>();

  async issue(uid: string): Promise<IssuedInvitation> {
    const code = `CODE-${uid}`;
    this.byCode.set(code, uid);
    return {code, expiresAt: "2026-10-22T00:00:00.000Z"};
  }

  async redeem(code: string): Promise<string | null> {
    const uid = this.byCode.get(code) ?? null;
    this.byCode.delete(code);
    return uid;
  }
}

export class MemorySessions implements RuntimeSessionAccess {
  readonly created: string[] = [];
  readonly revoked: string[] = [];

  readonly devices: SessionDevice[] = [];

  async createSession(uid: string, device: SessionDevice): Promise<string> {
    this.created.push(uid);
    this.devices.push(device);
    return `token-${uid}`;
  }

  async revokeSessionsOf(uid: string): Promise<void> {
    this.revoked.push(uid);
  }
}

export const licenseProof = {
  requiresActivationTokenForSetup: () => true,
  matchesActivationToken: (token: unknown) => token === "LIZENZ",
};
