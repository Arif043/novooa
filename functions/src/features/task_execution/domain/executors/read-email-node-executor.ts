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
    return executedNode(node, {
      ...textOutputs(event.message),
      sender: stringOutput(event.senderEmail),
      subject: stringOutput(event.subject),
      message: stringOutput(event.message),
      receivedAt: datetimeOutput(event.receivedAt),
    });
  },
};

export const readChannelEventNodeExecutor: NodeExecutor = {
  primitive: "readChannelEvent",
  async execute(node, runContext) {
    const config = channelEventConfigFrom(node);
    if (config.kind === "email") {
      const event = emailEventFrom(runContext.input);
      return executedNode(node, emailOutputs(event));
    }
    const event = messageEventFrom(runContext.input, eventTypeFor(config.kind));
    return executedNode(node, messageOutputs(event));
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
    message: stringOutput(event.message),
    receivedAt: datetimeOutput(event.receivedAt),
  };
}

function messageOutputs(event: MessageEvent) {
  return {
    ...textOutputs(event.message),
    sender: stringOutput(event.senderPhoneNumber),
    message: stringOutput(event.message),
    receivedAt: datetimeOutput(event.receivedAt),
  };
}

function channelEventConfigFrom(input: {config: unknown}): {kind: ChannelEventKind} {
  const config = input.config;
  if (!isRecord(config)) return {kind: "whatsapp"};
  const kind = config.kind;
  if (kind === "email" || kind === "whatsapp" || kind === "sms") return {kind};
  return {kind: "whatsapp"};
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
