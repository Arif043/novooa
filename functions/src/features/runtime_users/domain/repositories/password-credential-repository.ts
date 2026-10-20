import {type RuntimePassword} from "../entities/runtime-password.js";

/**
 * Passwörter der Konten, getrennt vom Konto: Ein Konto kann (künftig über SSO) auch ohne Passwort bestehen.
 * Gespeichert wird nur ein langsamer Hash.
 */
export interface PasswordCredentialRepository {
  hasAny(): Promise<boolean>;
  /** Prüft das Passwort; ein Konto ohne Passwort kostet genauso viel Zeit, damit es nicht erkennbar wird. */
  verify(uid: string | null, password: string): Promise<boolean>;
  set(uid: string, password: RuntimePassword): Promise<void>;
  remove(uid: string): Promise<void>;
}
