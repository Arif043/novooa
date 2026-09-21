import {Timestamp, type DocumentData} from "firebase-admin/firestore";
import {
  type MailConnector,
  type MailConnectorCredentials,
} from "../../domain/entities/mail-connector.js";
import {type MailConnectorAuthorization} from
  "../../domain/entities/mail-connector-authorization.js";
import {CredentialCipher} from "../security/credential-cipher.js";

export function authorizationDocument(input: MailConnectorAuthorization) {
  return {...input, expiresAt: Timestamp.fromDate(input.expiresAt), createdAt: Timestamp.now()};
}

export function connectorDocument(input: MailConnector) {
  return {
    ...input,
    subscriptionExpiresAt: timestampOrNull(input.subscriptionExpiresAt),
    createdAt: Timestamp.fromDate(input.createdAt),
    updatedAt: Timestamp.fromDate(input.updatedAt),
  };
}

export function credentialsDocument(input: MailConnectorCredentials, cipher: CredentialCipher) {
  return {payload: cipher.encrypt(JSON.stringify(input)), updatedAt: Timestamp.now()};
}

export function authorizationFrom(data: DocumentData): MailConnectorAuthorization | null {
  const expiresAt = dateFrom(data.expiresAt);
  if (!expiresAt || expiresAt <= new Date() || data.provider !== "microsoftGraph") return null;
  return {
    id: String(data.id ?? ""), teamId: String(data.teamId ?? ""), uid: String(data.uid ?? ""),
    provider: data.provider,
    deliveryTarget: deliveryTargetFrom(data.deliveryTarget),
    runtimeLicenseId: runtimeLicenseIdFrom(data.runtimeLicenseId),
    codeVerifier: String(data.codeVerifier ?? ""), expiresAt,
  };
}

export function connectorFrom(data: DocumentData, id: string): MailConnector {
  return {
    id, teamId: String(data.teamId ?? ""), createdByUid: String(data.createdByUid ?? ""),
    provider: providerFrom(data.provider), deliveryTarget: deliveryTargetFrom(data.deliveryTarget),
    runtimeLicenseId: runtimeLicenseIdFrom(data.runtimeLicenseId), emailAddress: String(data.emailAddress ?? ""),
    displayName: String(data.displayName ?? ""), status: statusFrom(data.status),
    subscriptionId: optionalString(data.subscriptionId),
    subscriptionExpiresAt: dateFrom(data.subscriptionExpiresAt),
    createdAt: dateFrom(data.createdAt) ?? new Date(0), updatedAt: dateFrom(data.updatedAt) ?? new Date(0),
  };
}

export function credentialsFrom(data: DocumentData, cipher: CredentialCipher): MailConnectorCredentials {
  const value = JSON.parse(cipher.decrypt(String(data.payload ?? ""))) as Record<string, unknown>;
  return {refreshToken: String(value.refreshToken ?? ""), subscriptionClientState: String(value.subscriptionClientState ?? "")};
}

function providerFrom(value: unknown): "microsoftGraph" {
  if (value !== "microsoftGraph") throw new Error("Unsupported mail connector provider.");
  return value;
}

function statusFrom(value: unknown): MailConnector["status"] {
  if (value === "active" || value === "reauthorizationRequired" || value === "disconnected") return value;
  throw new Error("Unsupported mail connector status.");
}

function deliveryTargetFrom(value: unknown): MailConnector["deliveryTarget"] {
  return value === "localRuntime" ? value : "cloud";
}

function runtimeLicenseIdFrom(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

function dateFrom(value: unknown): Date | null {
  return value instanceof Timestamp ? value.toDate() : null;
}

function optionalString(value: unknown): string | null {
  return typeof value === "string" && value ? value : null;
}

function timestampOrNull(value: Date | null): Timestamp | null {
  return value ? Timestamp.fromDate(value) : null;
}
