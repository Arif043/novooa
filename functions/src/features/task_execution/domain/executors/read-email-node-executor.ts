import {ok} from "neverthrow";
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
    const event = emailEventFrom(runContext.input);
    return ok(executedNode(node, {
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
      const event = emailEventFrom(runContext.input);
      return ok(executedNode(node, emailOutputs(event)));
    }
    const event = messageEventFrom(runContext.input, eventTypeFor(kind));
    return ok(executedNode(node, messageOutputs(event)));
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

function emailEventFrom(input: Record<string, unknown>): EmailEvent {
  const event = input.event;
  if (!isRecord(event) || event.type !== "emailReceived") {
    throw new Error("E-Mail lesen: Dieser TaskRun wurde nicht durch eine E-Mail gestartet.");
  }
  return {
    type: "emailReceived",
    senderEmail: stringField(event, "senderEmail"),
    subject: stringField(event, "subject"),
    message: stringField(event, "message"),
    receivedAt: stringField(event, "receivedAt"),
  };
}

function messageEventFrom(
  input: Record<string, unknown>,
  type: MessageEvent["type"],
): MessageEvent {
  const event = input.event;
  if (!isRecord(event) || event.type !== type) {
    throw new Error(`${labelFor(type)} lesen: Dieser TaskRun wurde nicht durch ${sourceFor(type)} gestartet.`);
  }
  return {
    type,
    senderPhoneNumber: stringField(event, "senderPhoneNumber"),
    message: stringField(event, "message"),
    receivedAt: stringField(event, "receivedAt"),
  };
}

function labelFor(type: MessageEvent["type"]): string {
  return type === "whatsappMessageReceived" ? "WhatsApp" : "SMS";
}

function sourceFor(type: MessageEvent["type"]): string {
  return type === "whatsappMessageReceived" ? "WhatsApp" : "eine SMS";
}

function stringField(data: Record<string, unknown>, key: string): string {
  const value = data[key];
  return typeof value === "string" ? value : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
