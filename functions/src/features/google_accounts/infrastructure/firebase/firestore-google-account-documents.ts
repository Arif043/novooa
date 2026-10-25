import {Timestamp, type DocumentData} from "firebase-admin/firestore";
import {
  type GoogleAccount,
  type GoogleAccountStatus,
  type GoogleDriveItem,
} from "../../domain/entities/google-account.js";
import {type GoogleAccountAuthorization} from "../../domain/entities/google-account-authorization.js";

export function authorizationDocument(authorization: GoogleAccountAuthorization): DocumentData {
  return {...authorization, expiresAt: Timestamp.fromDate(authorization.expiresAt)};
}

export function authorizationFrom(data: DocumentData, now: Date): GoogleAccountAuthorization | null {
  const expiresAt = dateFrom(data.expiresAt);
  if (expiresAt === null || expiresAt <= now) return null;
  return {
    id: requiredText(data.id), teamId: requiredText(data.teamId), runtimeLicenseId: requiredText(data.runtimeLicenseId),
    codeVerifier: requiredText(data.codeVerifier), expiresAt,
  };
}

export function accountDocument(account: GoogleAccount): DocumentData {
  return {
    ...account,
    createdAt: Timestamp.fromDate(account.createdAt),
    updatedAt: Timestamp.fromDate(account.updatedAt),
  };
}

export function accountFrom(data: DocumentData, id: string): GoogleAccount {
  return {
    id, teamId: requiredText(data.teamId), runtimeLicenseId: requiredText(data.runtimeLicenseId),
    googleUserId: requiredText(data.googleUserId), email: requiredText(data.email),
    status: statusFrom(data.status), sharedItems: itemsFrom(data.sharedItems),
    createdAt: dateFrom(data.createdAt) ?? new Date(0), updatedAt: dateFrom(data.updatedAt) ?? new Date(0),
  };
}

function statusFrom(value: unknown): GoogleAccountStatus {
  return value === "active" ? "active" : "reauthorizationRequired";
}

function itemsFrom(value: unknown): GoogleDriveItem[] {
  if (!Array.isArray(value)) return [];
  return value.flatMap((item: unknown) => {
    if (typeof item !== "object" || item === null) return [];
    const entry = item as Record<string, unknown>;
    if (typeof entry.id !== "string") return [];
    return [{id: entry.id, name: textOr(entry.name, entry.id), mimeType: textOr(entry.mimeType, "")}];
  });
}

function textOr(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}

function requiredText(value: unknown): string {
  if (typeof value === "string" && value.length > 0) return value;
  throw new Error("Unvollständiges Google-Konto in Firestore.");
}

function dateFrom(value: unknown): Date | null {
  return value instanceof Timestamp ? value.toDate() : null;
}
