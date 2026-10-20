import {type LoginName} from "../entities/login-name.js";
import {type NewRuntimeUser, type RuntimeUser, type RuntimeUserChanges} from "../entities/runtime-user.js";

/** Die Konten des aktiven Arbeitsbereichs. */
export interface RuntimeUserRepository {
  list(): Promise<RuntimeUser[]>;
  find(uid: string): Promise<RuntimeUser | null>;
  findByLoginName(loginName: LoginName): Promise<RuntimeUser | null>;
  /** Legt ein neues Konto ohne Passwort an. */
  create(user: NewRuntimeUser): Promise<RuntimeUser>;
  /** Ersteinrichtung: macht das Profil des Arbeitsbereichs zum ersten Admin-Konto. */
  claimWorkspaceOwner(user: Omit<NewRuntimeUser, "role">): Promise<RuntimeUser>;
  /** Die uid des Profils, dem der Arbeitsbereich gehört. */
  workspaceOwnerUid(): string;
  update(uid: string, changes: RuntimeUserChanges): Promise<RuntimeUser | null>;
  delete(uid: string): Promise<boolean>;
}
