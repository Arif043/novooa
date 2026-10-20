import {type RuntimeExecutor} from "../../../../db/database.js";
import {createLoginAttemptLimiter} from "../../../../shared/local/local-runtime-login-rate-limiter.js";
import {type LocalRuntimeRealtimeConnections} from "../../../../shared/local/local-runtime-realtime-connections.js";
import {type LocalRuntimeSessionStore} from "../../../../shared/local/local-runtime-session-store.js";
import {type RuntimeOwnershipProof} from "../../domain/repositories/runtime-ownership-proof.js";
import {type RuntimeSessionAccess} from "../../domain/repositories/runtime-session-access.js";
import {type RuntimeUserLimit} from "../../domain/repositories/runtime-user-limit.js";
import {
  ChangeOwnPassword,
  LoadSetupState,
  RecoverAdminAccess,
  RedeemInvitation,
  SetUpFirstAdmin,
  SignIn,
} from "../../domain/usecases/runtime-access.js";
import {CreateUser, DeleteUser, ListUsers, ResetUserPassword, UpdateUser} from "../../domain/usecases/runtime-user-management.js";
import {type AccountRoutesOptions} from "./local-runtime-account-routes.js";
import {type UserRoutesOptions} from "./local-runtime-user-routes.js";
import {SQLiteInvitationRepository} from "./sqlite-invitation-repository.js";
import {SQLitePasswordCredentialRepository} from "./sqlite-password-credential-repository.js";
import {SQLiteRuntimeUserRepository, type RuntimeUserWorkspace} from "./sqlite-runtime-user-repository.js";

export type RuntimeUsersDependencies = {
  database: RuntimeExecutor;
  workspace: () => RuntimeUserWorkspace;
  sessions: Pick<LocalRuntimeSessionStore, "createSession" | "deleteSessionsOf" | "isActive">;
  connections: Pick<LocalRuntimeRealtimeConnections, "closeInactive">;
  proof: RuntimeOwnershipProof;
  limit: RuntimeUserLimit;
  notifier: {publish(topic: string): void};
};

/** Baut Konten, Anmeldung und Benutzerverwaltung der Runtime aus SQLite und dem Sitzungs-Speicher. */
export function createRuntimeUsersModule(dependencies: RuntimeUsersDependencies): {
  account: AccountRoutesOptions; users: UserRoutesOptions;
} {
  const {database, proof, limit} = dependencies;
  const users = new SQLiteRuntimeUserRepository(database, dependencies.workspace);
  const passwords = new SQLitePasswordCredentialRepository(database);
  const invitations = new SQLiteInvitationRepository(database);
  const sessions = sessionAccessFor(dependencies);
  return {
    account: {
      setupState: new LoadSetupState(passwords),
      requiresLicenseToken: () => proof.requiresActivationTokenForSetup(),
      setUp: new SetUpFirstAdmin(users, passwords, proof),
      signIn: new SignIn(users, passwords, sessions),
      redeem: new RedeemInvitation(invitations, passwords, sessions),
      recover: new RecoverAdminAccess(users, passwords, proof, sessions),
      changePassword: new ChangeOwnPassword(passwords),
      users,
      limiter: createLoginAttemptLimiter(),
    },
    users: {
      list: new ListUsers(users, limit),
      create: new CreateUser(users, invitations, limit),
      update: new UpdateUser(users),
      resetPassword: new ResetUserPassword(users, passwords, invitations, sessions),
      remove: new DeleteUser(users, sessions),
      notifier: dependencies.notifier,
    },
  };
}

/** Beendete Sitzungen schließen auch ihre offenen Realtime-Verbindungen sofort. */
function sessionAccessFor({sessions, connections}: RuntimeUsersDependencies): RuntimeSessionAccess {
  return {
    createSession: (uid) => sessions.createSession(uid),
    revokeSessionsOf: async (uid) => {
      await sessions.deleteSessionsOf(uid);
      await connections.closeInactive((token) => sessions.isActive(token));
    },
  };
}
