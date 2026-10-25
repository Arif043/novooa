import {LoginName} from "../entities/login-name.js";
import {RuntimePassword} from "../entities/runtime-password.js";
import {displayNameFrom, type RuntimeUser} from "../entities/runtime-user.js";
import {SessionDevice, type SessionDeviceInput} from "../entities/session-device.js";
import {RuntimeUserError} from "../entities/runtime-user-error.js";
import {type InvitationRepository} from "../repositories/invitation-repository.js";
import {type PasswordCredentialRepository} from "../repositories/password-credential-repository.js";
import {type RuntimeOwnershipProof} from "../repositories/runtime-ownership-proof.js";
import {type RuntimeSessionAccess} from "../repositories/runtime-session-access.js";
import {type RuntimeUserRepository} from "../repositories/runtime-user-repository.js";

export type FirstAdminInput = {activationToken?: string; loginName: string; displayName: string; password: string};
export type SignInInput = {loginName: string; password: string; device?: SessionDeviceInput};
export type RedeemInput = {code: string; password: string; device?: SessionDeviceInput};
export type RecoverInput = {activationToken?: string; loginName: string; password: string; device?: SessionDeviceInput};

/** Die Runtime ist eingerichtet, sobald ein Konto ein Passwort hat. */
export class LoadSetupState {
  constructor(private readonly passwords: PasswordCredentialRepository) {}

  async needsSetup(): Promise<boolean> {
    return !await this.passwords.hasAny();
  }
}

/** Ersteinrichtung: Wer den Lizenz-Token besitzt, legt das erste Admin-Konto an. */
export class SetUpFirstAdmin {
  constructor(
    private readonly users: RuntimeUserRepository,
    private readonly passwords: PasswordCredentialRepository,
    private readonly proof: RuntimeOwnershipProof,
  ) {}

  async execute(input: FirstAdminInput): Promise<RuntimeUser> {
    ensureOwnership(this.proof, input.activationToken);
    const account = {loginName: LoginName.from(input.loginName), displayName: displayNameFrom(input.displayName)};
    const password = RuntimePassword.from(input.password);
    if (await this.passwords.hasAny()) {
      throw new RuntimeUserError("already_set_up", "Diese Runtime ist bereits eingerichtet.");
    }
    const owner = await this.users.claimWorkspaceOwner(account);
    await this.passwords.set(owner.uid, password);
    return {...owner, hasPassword: true};
  }
}

/** Anmeldename und Passwort gegen eine Sitzung tauschen. */
export class SignIn {
  constructor(
    private readonly users: RuntimeUserRepository,
    private readonly passwords: PasswordCredentialRepository,
    private readonly sessions: RuntimeSessionAccess,
  ) {}

  async execute({loginName, password, device}: SignInInput): Promise<string> {
    const name = LoginName.tryFrom(loginName);
    const user = name === null ? null : await this.users.findByLoginName(name);
    if (!await this.passwords.verify(user?.uid ?? null, password) || user === null) {
      throw new RuntimeUserError("invalid_credentials", "Anmeldename oder Passwort ist ungültig.");
    }
    return this.sessions.createSession(user.uid, SessionDevice.from(device));
  }
}

/** Einladungscode einlösen: eigenes Passwort setzen und gleich angemeldet sein. */
export class RedeemInvitation {
  constructor(
    private readonly invitations: InvitationRepository,
    private readonly passwords: PasswordCredentialRepository,
    private readonly sessions: RuntimeSessionAccess,
  ) {}

  async execute(input: RedeemInput): Promise<string> {
    const password = RuntimePassword.from(input.password);
    const uid = await this.invitations.redeem(input.code);
    if (uid === null) {
      throw new RuntimeUserError("invalid_invitation", "Der Einladungscode ist ungültig oder abgelaufen.");
    }
    await this.passwords.set(uid, password);
    return this.sessions.createSession(uid, SessionDevice.from(input.device));
  }
}

/** Notzugang: Mit dem Lizenz-Token setzt man das Passwort eines Admins neu. */
export class RecoverAdminAccess {
  constructor(
    private readonly users: RuntimeUserRepository,
    private readonly passwords: PasswordCredentialRepository,
    private readonly proof: RuntimeOwnershipProof,
    private readonly sessions: RuntimeSessionAccess,
  ) {}

  async execute(input: RecoverInput): Promise<string> {
    ensureOwnership(this.proof, input.activationToken);
    const password = RuntimePassword.from(input.password);
    const name = LoginName.tryFrom(input.loginName);
    const user = name === null ? null : await this.users.findByLoginName(name);
    if (user?.role !== "admin") {
      throw new RuntimeUserError("user_not_found", "Es gibt keinen Admin mit diesem Anmeldenamen.");
    }
    await this.passwords.set(user.uid, password);
    await this.sessions.revokeSessionsOf(user.uid);
    return this.sessions.createSession(user.uid, SessionDevice.from(input.device));
  }
}

/** Das eigene Passwort ändern; andere Geräte bleiben angemeldet. */
export class ChangeOwnPassword {
  constructor(private readonly passwords: PasswordCredentialRepository) {}

  execute(uid: string, password: string): Promise<void> {
    return this.passwords.set(uid, RuntimePassword.from(password));
  }
}

function ensureOwnership(proof: RuntimeOwnershipProof, activationToken: string | undefined): void {
  if (proof.requiresActivationTokenForSetup() && !proof.matchesActivationToken(activationToken)) {
    throw new RuntimeUserError("license_token_mismatch", "Der Lizenz-Token passt nicht zu dieser Runtime.");
  }
}
