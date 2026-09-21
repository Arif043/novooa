import {Timestamp, type DocumentData} from "firebase-admin/firestore";
import {type EmailReceivedEvent} from
  "../../domain/entities/channel-message-event.js";
import {
  type RuntimeMailRelayDeadLetter,
  type RuntimeMailRelayDelivery,
  type RuntimeMailRelayEvent,
} from "../../domain/entities/runtime-mail-relay-event.js";

export type RelayEventDocument = {
  licenseId: string;
  workspaceId: string;
  connectorId: string;
  event: EmailReceivedEvent;
  createdAt: Timestamp;
  attempts: number;
  status: "pending" | "leased";
  nextAttemptAt: Timestamp;
  leaseExpiresAt: Timestamp | null;
  receipt: string | null;
  lastError: string | null;
};

export function eventDocument(input: {
  licenseId: string;
  workspaceId: string;
  event: RuntimeMailRelayEvent;
}): RelayEventDocument {
  const now = Timestamp.now();
  return {
    licenseId: input.licenseId, workspaceId: input.workspaceId,
    connectorId: input.event.connectorId, event: input.event.event,
    createdAt: Timestamp.fromDate(new Date(input.event.createdAt)), attempts: 0,
    status: "pending", nextAttemptAt: now, leaseExpiresAt: null, receipt: null,
    lastError: null,
  };
}

export function deliveryFrom(
  id: string,
  data: DocumentData,
  receipt: string,
): RuntimeMailRelayDelivery | null {
  const event = eventFrom(data.event);
  const createdAt = dateFrom(data.createdAt);
  const connectorId = text(data.connectorId);
  if (!event || !createdAt || !connectorId) return null;
  return {
    eventId: id, connectorId, event, receipt,
    attempt: numberFrom(data.attempts), createdAt: createdAt.toISOString(),
  };
}

export function deadLetterDocument(
  active: DocumentData,
  failedAt: Date,
  error: string,
): DocumentData {
  return {
    licenseId: text(active.licenseId), workspaceId: text(active.workspaceId),
    connectorId: text(active.connectorId), event: active.event,
    createdAt: active.createdAt, attempts: numberFrom(active.attempts),
    failedAt: Timestamp.fromDate(failedAt), lastError: error, replayedAt: null,
  };
}

export function deadLetterFrom(
  id: string,
  data: DocumentData,
): RuntimeMailRelayDeadLetter | null {
  const event = eventFrom(data.event);
  const createdAt = dateFrom(data.createdAt);
  const failedAt = dateFrom(data.failedAt);
  const connectorId = text(data.connectorId);
  if (!event || !createdAt || !failedAt || !connectorId) return null;
  return {
    eventId: id, connectorId, event, createdAt: createdAt.toISOString(),
    attempts: numberFrom(data.attempts), failedAt: failedAt.toISOString(),
    lastError: text(data.lastError), replayedAt: dateFrom(data.replayedAt)?.toISOString() ?? null,
  };
}

export function pendingDocumentFromDeadLetter(data: DocumentData, now: Date): RelayEventDocument {
  return {
    licenseId: text(data.licenseId), workspaceId: text(data.workspaceId),
    connectorId: text(data.connectorId), event: data.event as EmailReceivedEvent,
    createdAt: data.createdAt as Timestamp, attempts: 0, status: "pending",
    nextAttemptAt: Timestamp.fromDate(now), leaseExpiresAt: null, receipt: null,
    lastError: null,
  };
}

function eventFrom(value: unknown): EmailReceivedEvent | null {
  if (!isRecord(value) || value.type !== "emailReceived" || value.provider !== "microsoftGraph") {
    return null;
  }
  const strings = ["providerMessageId", "receivedAt", "senderEmail", "recipientEmail", "subject", "message"];
  if (!strings.every((key) => typeof value[key] === "string")) return null;
  return value as EmailReceivedEvent;
}

function dateFrom(value: unknown): Date | null {
  return value instanceof Timestamp ? value.toDate() : null;
}

function numberFrom(value: unknown): number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0 ? value : 0;
}

function text(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
