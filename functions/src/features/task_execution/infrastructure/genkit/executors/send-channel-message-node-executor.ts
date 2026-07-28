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
import {type TaskMessageKind} from "../../../domain/repositories/task-message-sender.js";

export const sendChannelMessageNodeExecutor: NodeExecutor = {
  primitive: "sendChannelMessage",
  async execute(input, runContext) {
    const config = sendConfigFrom(input.node.config);
    const recipient = runContext.resolveTemplates(config.recipient).trim();
    const body = runContext.resolveTemplates(config.message).trim();
    if (!recipient) throw new Error(`${labelFor(config.kind)} senden: Empfänger fehlt.`);
    if (!body) throw new Error(`${labelFor(config.kind)} senden: Nachricht fehlt.`);
    logSendStarted(runContext.teamId, input.node, config.kind, recipient, body);
    const sent = await sendMessage(runContext, config.kind, recipient, body);
    logInfo("send_channel_node.sent", {
      teamId: runContext.teamId,
      ...nodeSummary(input.node),
      kind: config.kind,
      channelId: sent.channelId,
      outboundId: sent.outboundId,
      providerMessageId: sent.providerMessageId,
    });
    return executedNode(input.node, {
      text: stringOutput(body),
      recipient: stringOutput(recipient),
      channelId: stringOutput(sent.channelId),
      providerMessageId: stringOutput(sent.providerMessageId),
    });
  },
};

function sendConfigFrom(config: unknown): {
  kind: TaskMessageKind;
  recipient: string;
  message: string;
} {
  if (!isRecord(config)) return {kind: "whatsapp", recipient: "", message: ""};
  return {
    kind: kindFrom(config.kind),
    recipient: stringFrom(config.recipient),
    message: stringFrom(config.message),
  };
}

async function sendMessage(
  runContext: Parameters<NodeExecutor["execute"]>[1],
  kind: TaskMessageKind,
  recipient: string,
  body: string,
) {
  try {
    return await runContext.messageSender.send({
      teamId: runContext.teamId,
      kind,
      recipient,
      body,
    });
  } catch (error) {
    logError("send_channel_node.failed", {
      teamId: runContext.teamId,
      kind,
      error: errorDetails(error),
    });
    throw error;
  }
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
