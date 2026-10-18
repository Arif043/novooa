import {ok} from "neverthrow";
import {
  executedNode,
  stringOutput,
  type NodeExecutor,
} from "./node-executor.js";
import {
  type SendTaskMessageInput,
  type TaskMessageKind,
} from "../repositories/task-message-sender.js";

export type TaskMessageObserver = {
  started(event: TaskMessageStarted): void;
  sent(event: TaskMessageSent): void;
  failed(event: TaskMessageFailed): void;
};

export type TaskMessageStarted = {
  teamId: string;
  node: Parameters<NodeExecutor["execute"]>[0];
  kind: TaskMessageKind;
  recipient: string;
  body: string;
};

export type TaskMessageSent = TaskMessageStarted & {
  channelId: string;
  outboundId: string;
  providerMessageId: string;
};

export type TaskMessageFailed = {
  teamId: string;
  kind: TaskMessageKind;
  error: unknown;
};

const noopMessageObserver: TaskMessageObserver = {
  started: () => undefined,
  sent: () => undefined,
  failed: () => undefined,
};

type MessageRequest = {
  kind: TaskMessageKind;
  connectorId: string;
  recipient: string;
  subject: string;
  body: string;
};

export function createSendChannelMessageNodeExecutor(
  observer: TaskMessageObserver = noopMessageObserver,
): NodeExecutor {
  return {
    primitive: "sendChannelMessage",
    async execute(node, runContext) {
      const config = sendConfigFrom(node.config);
      const recipient = runContext.templateExpressionResolver.resolveText(config.recipient).trim();
      const body = runContext.templateExpressionResolver.resolveText(config.message).trim();
      const subject = subjectFrom(config.subject, runContext);
      const connectorId = connectorIdFrom(config.connectorId, runContext.input);
      if (!recipient) throw new Error(`${labelFor(config.kind)} senden: Empfänger fehlt.`);
      if (!body) throw new Error(`${labelFor(config.kind)} senden: Nachricht fehlt.`);
      const started = {teamId: runContext.teamId, node, kind: config.kind, recipient, body};
      observer.started(started);
      const sent = await sendMessage(runContext, {
        kind: config.kind,
        connectorId,
        recipient,
        subject,
        body,
      }, observer);
      observer.sent({...started, ...sent});
      return ok(executedNode(node, {
        value: stringOutput(body),
        recipient: stringOutput(recipient),
        channelId: stringOutput(sent.channelId),
        providerMessageId: stringOutput(sent.providerMessageId),
      }));
    },
  };
}

function sendConfigFrom(config: unknown): {
  kind: TaskMessageKind;
  connectorId: string;
  recipient: string;
  subject: string;
  message: string;
} {
  if (!isRecord(config)) return emptyConfig();
  return {
    kind: kindFrom(config.kind),
    connectorId: stringFrom(config.connectorId),
    recipient: stringFrom(config.recipient),
    subject: stringFrom(config.subject),
    message: stringFrom(config.message),
  };
}

async function sendMessage(
  runContext: Parameters<NodeExecutor["execute"]>[1],
  input: MessageRequest,
  observer: TaskMessageObserver,
) {
  try {
    return await runContext.messageSender.send(
      messageInputFor(runContext.teamId, input),
    );
  } catch (error) {
    observer.failed({teamId: runContext.teamId, kind: input.kind, error});
    throw error;
  }
}

function messageInputFor(
  teamId: string,
  input: MessageRequest,
): SendTaskMessageInput {
  if (input.kind === "email") {
    if (!input.connectorId) {
      throw new Error("E-Mail senden: Verbundenes Postfach fehlt.");
    }
    return {teamId, ...input};
  }
  return {
    teamId,
    kind: input.kind,
    recipient: input.recipient,
    subject: input.subject,
    body: input.body,
  };
}

function emptyConfig() {
  return {kind: "whatsapp" as const, connectorId: "", recipient: "", subject: "", message: ""};
}

function subjectFrom(
  configuredSubject: string,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): string {
  const subject = runContext.templateExpressionResolver.resolveText(configuredSubject).trim();
  if (subject) return subject;
  return replySubjectFrom(runContext.input) || "Nachricht von novooa";
}

function replySubjectFrom(input: Record<string, unknown>): string {
  const event = input.event;
  if (!isRecord(event) || event.type !== "emailReceived") return "";
  const subject = stringFrom(event.subject).trim();
  return subject ? `Re: ${subject}` : "";
}

function connectorIdFrom(configuredId: string, input: Record<string, unknown>): string {
  if (configuredId) return configuredId;
  const event = input.event;
  return isRecord(event) && event.type === "emailReceived" ? stringFrom(event.connectorId) : "";
}

function kindFrom(value: unknown): TaskMessageKind {
  if (value === "email" || value === "whatsapp" || value === "sms") return value;
  return "whatsapp";
}

function labelFor(kind: TaskMessageKind): string {
  if (kind === "email") return "E-Mail";
  return kind === "whatsapp" ? "WhatsApp" : "SMS";
}

function stringFrom(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
