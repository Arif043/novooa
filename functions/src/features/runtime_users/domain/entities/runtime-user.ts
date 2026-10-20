import {type LoginName} from "./login-name.js";
import {RuntimeUserError} from "./runtime-user-error.js";

/** Admins verwalten Benutzer, Lizenz und Anbindungen; Mitglieder arbeiten mit Aufgaben und Inhalten. */
export type RuntimeRole = "admin" | "member";

export const runtimeRoles: readonly RuntimeRole[] = ["admin", "member"];

export type RuntimeUser = {
  uid: string;
  loginName: string;
  displayName: string;
  role: RuntimeRole;
  /** `false`, solange die Einladung nicht eingelöst ist (oder nach dem Zurücksetzen). */
  hasPassword: boolean;
  createdAt: string;
};

/** Wer eine Anfrage stellt: aus der Sitzung abgeleitet. */
export type RuntimeActor = {uid: string; role: RuntimeRole};

export type NewRuntimeUser = {loginName: LoginName; displayName: string; role: RuntimeRole};

export type RuntimeUserChanges = {displayName?: string; role?: RuntimeRole};

const maximumDisplayNameLength = 100;

export function displayNameFrom(raw: string): string {
  const name = raw.trim();
  if (name.length === 0 || name.length > maximumDisplayNameLength) {
    throw new RuntimeUserError("invalid_input", `Der Name braucht 1 bis ${maximumDisplayNameLength} Zeichen.`);
  }
  return name;
}

export function isRuntimeRole(value: unknown): value is RuntimeRole {
  return runtimeRoles.includes(value as RuntimeRole);
}
