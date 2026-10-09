import {
  datetimeOutput,
  executedNode,
  stringOutput,
  textOutputs,
  type NodeExecutor,
} from "./node-executor.js";
import {type NodeOutputValue} from "../entities/task.js";

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

/**
 * Liefert flache Ausgabewerte unter den im Baustein konfigurierten,
 * graph-weit eindeutigen Namen — ohne `value`, wie eine strukturierte
 * Prompt-Ausgabe.
 */
export const readChannelEventNodeExecutor: NodeExecutor = {
  primitive: "readChannelEvent",
  async execute(node, runContext) {
    const config = channelEventConfigFrom(node);
    if (config.kind === "email") {
      const event = emailEventFrom(runContext.input);
      return executedNode(node, namedOutputs(config.outputNames, flatEmailOutputs(event)));
    }
    const event = messageEventFrom(runContext.input, eventTypeFor(config.kind));
    return executedNode(node, namedOutputs(config.outputNames, flatMessageOutputs(event)));
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

type ChannelEventField = "sender" | "subject" | "message" | "receivedAt";
type ChannelEventOutputNames = Record<ChannelEventField, string>;
type ChannelEventConfig = {kind: ChannelEventKind; outputNames: ChannelEventOutputNames};

const defaultOutputNames: ChannelEventOutputNames = {
  sender: "sender",
  subject: "subject",
  message: "message",
  receivedAt: "receivedAt",
};

function flatEmailOutputs(event: EmailEvent): Partial<Record<ChannelEventField, NodeOutputValue>> {
  return {
    sender: stringOutput(event.senderEmail),
    subject: stringOutput(event.subject),
    message: stringOutput(event.message),
    receivedAt: datetimeOutput(event.receivedAt),
  };
}

function flatMessageOutputs(event: MessageEvent): Partial<Record<ChannelEventField, NodeOutputValue>> {
  return {
    sender: stringOutput(event.senderPhoneNumber),
    message: stringOutput(event.message),
    receivedAt: datetimeOutput(event.receivedAt),
  };
}

function namedOutputs(
  names: ChannelEventOutputNames,
  outputs: Partial<Record<ChannelEventField, NodeOutputValue>>,
): Record<string, NodeOutputValue> {
  const named: Record<string, NodeOutputValue> = {};
  for (const [field, output] of Object.entries(outputs) as [ChannelEventField, NodeOutputValue][]) {
    named[names[field]] = output;
  }
  return named;
}

function channelEventConfigFrom(input: {config: unknown}): ChannelEventConfig {
  const config = isRecord(input.config) ? input.config : {};
  return {kind: channelEventKindFrom(config.kind), outputNames: outputNamesFrom(config.outputNames)};
}

function channelEventKindFrom(kind: unknown): ChannelEventKind {
  return kind === "email" || kind === "sms" ? kind : "whatsapp";
}

function outputNamesFrom(value: unknown): ChannelEventOutputNames {
  const names = isRecord(value) ? value : {};
  const nameFor = (field: ChannelEventField) => {
    const name = names[field];
    return typeof name === "string" && name.trim().length > 0 ? name.trim() : defaultOutputNames[field];
  };
  return {
    sender: nameFor("sender"),
    subject: nameFor("subject"),
    message: nameFor("message"),
    receivedAt: nameFor("receivedAt"),
  };
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
