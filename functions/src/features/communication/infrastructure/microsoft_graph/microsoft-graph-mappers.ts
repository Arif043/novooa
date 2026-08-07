import {type ConnectorMailMessage} from "../../domain/entities/mail-message.js";
import {type MailProviderToken} from "../../domain/repositories/mail-provider.js";

export function tokenFrom(data: Record<string, unknown>): MailProviderToken {
  const accessToken = stringFrom(data.access_token);
  const refreshToken = stringFrom(data.refresh_token);
  if (!accessToken || !refreshToken) throw new Error("Microsoft token response is incomplete.");
  return {accessToken, refreshToken};
}

export function messageFrom(data: Record<string, unknown>): ConnectorMailMessage {
  const id = stringFrom(data.id);
  const senderEmail = emailFrom(data.from);
  const recipientEmail = firstRecipientFrom(data.toRecipients);
  const receivedAt = dateFrom(data.receivedDateTime);
  if (!id || !senderEmail || !recipientEmail || !receivedAt) throw new Error("Microsoft message is incomplete.");
  return {
    id,
    senderEmail,
    recipientEmail,
    subject: stringFrom(data.subject),
    body: bodyFrom(data.body),
    receivedAt,
  };
}

export function stringFrom(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function emailFrom(value: unknown): string {
  if (!isRecord(value) || !isRecord(value.emailAddress)) return "";
  return stringFrom(value.emailAddress.address);
}

function firstRecipientFrom(value: unknown): string {
  if (!Array.isArray(value) || value.length === 0) return "";
  return emailFrom(value[0]);
}

function bodyFrom(value: unknown): string {
  return isRecord(value) ? stringFrom(value.content) : "";
}

function dateFrom(value: unknown): Date | null {
  if (typeof value !== "string") return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
