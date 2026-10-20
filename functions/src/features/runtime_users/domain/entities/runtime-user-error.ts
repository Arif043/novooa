/** Fachliche Fehler der Benutzerkonten; der Code bestimmt die HTTP-Antwort. */
export type RuntimeUserErrorCode =
  | "invalid_input"
  | "invalid_credentials"
  | "invalid_invitation"
  | "license_token_mismatch"
  | "already_set_up"
  | "user_not_found"
  | "login_name_taken"
  | "user_limit_reached"
  | "last_admin"
  | "own_account"
  | "workspace_owner";

export class RuntimeUserError extends Error {
  constructor(readonly code: RuntimeUserErrorCode, message: string) {
    super(message);
    this.name = "RuntimeUserError";
  }
}
