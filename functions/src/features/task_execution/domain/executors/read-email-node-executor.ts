import {err, ok, type Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
import {
  datetimeOutput,
  executedNode,
  stringOutput,
  textOutputs,
  type NodeExecutor,
} from "./node-executor.js";

export const readEmailNodeExecutor: NodeExecutor = {
  primitive: "readEmail",
  async execute(node, runContext) {
    return emailEventFrom(runContext.input).map((event) => executedNode(node, {
      ...textOutputs(event.message),
      sender: stringOutput(event.senderEmail),
      subject: stringOutput(event.subject),
      message: stringOutput(event.message),
      receivedAt: datetimeOutput(event.receivedAt),
    }));
  },
};

/**
 * Der Nachrichtentext ist der Hauptwert (`value`); Absender, Betreff und
 * Ankunftszeit sind weitere Werte, die der Builder per `outputs`
 * benennt.
 */
export const readChannelEventNodeExecutor: NodeExecutor = {
  primitive: "readChannelEvent",
  async execute(node, runContext) {
    const kind = channelEventKindFrom(node.config);
    if (kind === "email") {
      return emailEventFrom(runContext.input).map((event) => executedNode(node, emailOutputs(event)));
    }
    return messageEventFrom(runContext.input, kind).map((event) => executedNode(node, messageOutputs(event)));
  },
};

type EmailEvent = {
  type: "emailReceived";
  senderEmail: string;
  subject: string;
  message: string;
  receivedAt: string;
};

type MessageEvent = {
  type: "whatsappMessageReceived" | "smsMessageReceived";
  senderPhoneNumber: string;
  message: string;
  receivedAt: string;
};

type ChannelEventKind = "email" | "whatsapp" | "sms";

function emailOutputs(event: EmailEvent) {
  return {
    ...textOutputs(event.message),
    sender: stringOutput(event.senderEmail),
    subject: stringOutput(event.subject),
    receivedAt: datetimeOutput(event.receivedAt),
  };
}

function messageOutputs(event: MessageEvent) {
  return {
    ...textOutputs(event.message),
    sender: stringOutput(event.senderPhoneNumber),
    receivedAt: datetimeOutput(event.receivedAt),
  };
}

function channelEventKindFrom(config: unknown): ChannelEventKind {
  const kind = isRecord(config) ? config.kind : undefined;
  return kind === "email" || kind === "sms" ? kind : "whatsapp";
}

function eventTypeFor(kind: Exclude<ChannelEventKind, "email">): MessageEvent["type"] {
  return kind === "whatsapp" ? "whatsappMessageReceived" : "smsMessageReceived";
}

function emailEventFrom(input: Record<string, unknown>): Result<EmailEvent, NodeFailure> {
  const event = input.event;
  if (!isRecord(event) || event.type !== "emailReceived") return err(nodeFailures.triggerMismatch("email"));
  return ok({
    type: "emailReceived",
    senderEmail: stringField(event, "senderEmail"),
    subject: stringField(event, "subject"),
    message: stringField(event, "message"),
    receivedAt: stringField(event, "receivedAt"),
  });
}

function messageEventFrom(
  input: Record<string, unknown>,
  kind: Exclude<ChannelEventKind, "email">,
): Result<MessageEvent, NodeFailure> {
  const type = eventTypeFor(kind);
  const event = input.event;
  if (!isRecord(event) || event.type !== type) return err(nodeFailures.triggerMismatch(kind));
  return ok({
    type,
    senderPhoneNumber: stringField(event, "senderPhoneNumber"),
    message: stringField(event, "message"),
    receivedAt: stringField(event, "receivedAt"),
  });
}



function stringField(data: Record<string, unknown>, key: string): string {
  const value = data[key];
  return typeof value === "string" ? value : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
