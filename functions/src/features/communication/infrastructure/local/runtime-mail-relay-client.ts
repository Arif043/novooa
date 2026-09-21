import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {
  type RuntimeMailRelayDeadLetter,
  type RuntimeMailRelayDelivery,
} from "../../domain/entities/runtime-mail-relay-event.js";

export type RelayedMailMessage = {
  connectorId: string;
  recipient: string;
  subject: string;
  body: string;
};

export type RelayedMailMessageReceipt = {
  outboundId: string;
  providerMessageId: string;
  channelId: string;
};

export interface RuntimeMailRelayClient {
  beginMicrosoftAuthorization(license: SignedRuntimeLicense): Promise<{authorizationUrl: string}>;
  pull(license: SignedRuntimeLicense, limit: number): Promise<RuntimeMailRelayDelivery[]>;
  acknowledge(license: SignedRuntimeLicense, delivery: RuntimeMailRelayDelivery): Promise<void>;
  reject(license: SignedRuntimeLicense, delivery: RuntimeMailRelayDelivery, error: string): Promise<void>;
  sendEmail(license: SignedRuntimeLicense, message: RelayedMailMessage): Promise<RelayedMailMessageReceipt>;
  listDeadLetters(license: SignedRuntimeLicense): Promise<RuntimeMailRelayDeadLetter[]>;
  replayDeadLetter(license: SignedRuntimeLicense, eventId: string): Promise<void>;
}

export class HttpRuntimeMailRelayClient implements RuntimeMailRelayClient {
  private readonly endpoint: URL;

  constructor(endpoint: string) {
    this.endpoint = new URL(endpoint);
    if (this.endpoint.protocol !== "https:") throw new Error("Der Mail-Relay muss HTTPS verwenden.");
  }

  async beginMicrosoftAuthorization(license: SignedRuntimeLicense) {
    return authorizationFrom(await this.request({type: "beginMicrosoftAuthorization", license}));
  }

  async pull(license: SignedRuntimeLicense, limit: number) {
    return deliveriesFrom(await this.request({type: "pullEvents", license, limit}));
  }

  async acknowledge(license: SignedRuntimeLicense, delivery: RuntimeMailRelayDelivery) {
    await this.request({type: "acknowledgeEvent", license, eventId: delivery.eventId, receipt: delivery.receipt});
  }

  async reject(license: SignedRuntimeLicense, delivery: RuntimeMailRelayDelivery, error: string) {
    await this.request({type: "rejectEvent", license, eventId: delivery.eventId, receipt: delivery.receipt, error});
  }

  async sendEmail(license: SignedRuntimeLicense, message: RelayedMailMessage) {
    return receiptFrom(await this.request({type: "sendEmail", license, ...message}));
  }

  async listDeadLetters(license: SignedRuntimeLicense) {
    return deadLettersFrom(await this.request({type: "listDeadLetters", license}));
  }

  async replayDeadLetter(license: SignedRuntimeLicense, eventId: string): Promise<void> {
    await this.request({type: "replayDeadLetter", license, eventId});
  }

  private async request(body: object): Promise<Record<string, unknown>> {
    const response = await fetch(this.endpoint, {
      method: "POST", headers: {"content-type": "application/json"},
      body: JSON.stringify(body), signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) throw new Error("Der Mail-Relay hat die Anfrage abgelehnt.");
    return record(await response.json());
  }
}

export class UnavailableRuntimeMailRelayClient implements RuntimeMailRelayClient {
  async beginMicrosoftAuthorization(): Promise<{authorizationUrl: string}> { throw unavailable(); }
  async pull(): Promise<RuntimeMailRelayDelivery[]> { throw unavailable(); }
  async acknowledge(): Promise<void> { throw unavailable(); }
  async reject(): Promise<void> { throw unavailable(); }
  async sendEmail(): Promise<RelayedMailMessageReceipt> { throw unavailable(); }
  async listDeadLetters(): Promise<RuntimeMailRelayDeadLetter[]> { throw unavailable(); }
  async replayDeadLetter(): Promise<void> { throw unavailable(); }
}

function authorizationFrom(value: Record<string, unknown>): {authorizationUrl: string} {
  return {authorizationUrl: text(value.authorizationUrl, "authorizationUrl")};
}

function deliveriesFrom(value: Record<string, unknown>): RuntimeMailRelayDelivery[] {
  if (!Array.isArray(value.events)) throw new Error("Der Mail-Relay hat ungültige Ereignisse geliefert.");
  return value.events.map(deliveryFrom);
}

function deliveryFrom(value: unknown): RuntimeMailRelayDelivery {
  const item = record(value); const event = emailEventFrom(item.event);
  return {eventId: text(item.eventId, "eventId"), connectorId: text(item.connectorId, "connectorId"), event,
    receipt: text(item.receipt, "receipt"), attempt: integer(item.attempt, "attempt"), createdAt: text(item.createdAt, "createdAt")};
}

function receiptFrom(value: Record<string, unknown>): RelayedMailMessageReceipt {
  const sent = record(value.sent);
  return {outboundId: text(sent.outboundId, "outboundId"), providerMessageId: text(sent.providerMessageId, "providerMessageId"), channelId: text(sent.channelId, "channelId")};
}

function deadLettersFrom(value: Record<string, unknown>): RuntimeMailRelayDeadLetter[] {
  if (!Array.isArray(value.items)) throw new Error("Der Mail-Relay hat ungültige Dead-Letter-Ereignisse geliefert.");
  return value.items.map((item) => {
    const entry = record(item); const event = emailEventFrom(entry.event);
    return {eventId: text(entry.eventId, "eventId"), connectorId: text(entry.connectorId, "connectorId"), event,
      createdAt: text(entry.createdAt, "createdAt"), attempts: integer(entry.attempts, "attempts"),
      failedAt: text(entry.failedAt, "failedAt"), lastError: text(entry.lastError, "lastError"),
      replayedAt: optionalText(entry.replayedAt) ?? null};
  });
}

function emailEventFrom(value: unknown): RuntimeMailRelayDelivery["event"] {
  const event = record(value);
  if (event.type !== "emailReceived" || event.provider !== "microsoftGraph") throw new Error("Das Mail-Ereignis ist ungültig.");
  return {type: "emailReceived", provider: "microsoftGraph", providerMessageId: text(event.providerMessageId, "providerMessageId"),
    receivedAt: text(event.receivedAt, "receivedAt"), connectorId: optionalText(event.connectorId) ?? undefined,
    senderEmail: text(event.senderEmail, "senderEmail"), recipientEmail: text(event.recipientEmail, "recipientEmail"),
    subject: text(event.subject, "subject"), message: text(event.message, "message"), raw: stringRecord(event.raw)};
}

function stringRecord(value: unknown): Record<string, string> {
  const data = record(value);
  return Object.fromEntries(Object.entries(data).map(([key, item]) => [key, text(item, key)]));
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Die Mail-Relay-Antwort ist ungültig.");
}

function text(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error(`${name} ist ungültig.`);
  return value;
}

function optionalText(value: unknown): string | null | undefined {
  if (value === undefined) return undefined;
  if (value === null) return null;
  return text(value, "Wert");
}

function integer(value: unknown, name: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < 0) throw new Error(`${name} ist ungültig.`);
  return value;
}

function unavailable(): Error {
  return new Error("Der novooa Mail-Relay ist nicht konfiguriert.");
}
