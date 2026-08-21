import {
  executedNode,
  stringOutput,
  type NodeExecutor,
} from "../runner/node-executor.js";
import {
  errorDetails,
  logError,
  logInfo,
  nodeSummary,
  textSummary,
} from "../runner/structured-logger.js";
import {
  type SendTaskMessageInput,
  type TaskMessageKind,
} from "../../../domain/repositories/task-message-sender.js";

export const sendChannelMessageNodeExecutor: NodeExecutor = {
  primitive: "sendChannelMessage",
  async execute(input, runContext) {
    const config = sendConfigFrom(input.node.config);
    const recipient = runContext.resolveTemplates(config.recipient).trim();
    const body = runContext.resolveTemplates(config.message).trim();
    const subject = subjectFrom(config.subject, runContext);
    const connectorId = connectorIdFrom(config.connectorId, runContext.input);
    if (!recipient) throw new Error(`${labelFor(config.kind)} senden: Empfänger fehlt.`);
    if (!body) throw new Error(`${labelFor(config.kind)} senden: Nachricht fehlt.`);
    logSendStarted(runContext.teamId, input.node, config.kind, recipient, body);
    const sent = await sendMessage(runContext, {
      kind: config.kind,
      connectorId,
      recipient,
      subject,
      body,
    });
    logInfo("send_channel_node.sent", {
      teamId: runContext.teamId,
      ...nodeSummary(input.node),
      kind: config.kind,
      channelId: sent.channelId,
      outboundId: sent.outboundId,
      providerMessageId: sent.providerMessageId,
    });
    return executedNode(input.node, {
      value: stringOutput(body),
      text: stringOutput(body),
      recipient: stringOutput(recipient),
      channelId: stringOutput(sent.channelId),
      providerMessageId: stringOutput(sent.providerMessageId),
    });
  },
};

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
  input: {
    kind: TaskMessageKind;
    connectorId: string;
    recipient: string;
    subject: string;
    body: string;
  },
) {
  try {
    return await runContext.messageSender.send(messageInputFor(runContext.teamId, input));
  } catch (error) {
    logError("send_channel_node.failed", {
      teamId: runContext.teamId,
      kind: input.kind,
      error: errorDetails(error),
    });
    throw error;
  }
}

function messageInputFor(
  teamId: string,
  input: {
    kind: TaskMessageKind;
    connectorId: string;
    recipient: string;
    subject: string;
    body: string;
  },
): SendTaskMessageInput {
  if (input.kind !== "email") return {teamId, ...input};
  if (!input.connectorId) throw new Error("E-Mail senden: Verbundenes Postfach fehlt.");
  return {teamId, ...input};
}

function emptyConfig() {
  return {kind: "whatsapp" as const, connectorId: "", recipient: "", subject: "", message: ""};
}

function subjectFrom(
  configuredSubject: string,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): string {
  const subject = runContext.resolveTemplates(configuredSubject).trim();
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

function logSendStarted(
  teamId: string,
  node: Parameters<typeof nodeSummary>[0],
  kind: TaskMessageKind,
  recipient: string,
  body: string,
): void {
  logInfo("send_channel_node.started", {
    teamId,
    ...nodeSummary(node),
    kind,
    recipientLength: recipient.length,
    ...textSummary(body, "message"),
  });
}

function kindFrom(value: unknown): TaskMessageKind {
  if (value === "email" || value === "whatsapp" || value === "sms") {
    return value;
  }
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
