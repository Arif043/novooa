import {
  executedNode,
  stringOutput,
  type NodeExecutor,
} from "../task-runner/node-executor.js";
import {
  errorDetails,
  logError,
  logInfo,
  nodeSummary,
  textSummary,
} from "../task-runner/structured-logger.js";
import {sendTeamChannelMessage} from "../channels/team-channel-message-sender.js";
import {sendTeamEmailMessage} from "../channels/team-email-message-sender.js";
import {
  requiredSendgridApiKey,
  sendgridApiKey,
} from "../channels/sendgrid-secrets.js";
import {
  requiredSecret,
  twilioAccountSid,
  twilioAuthToken,
} from "../channels/twilio-secrets.js";

type SendKind = "email" | "whatsapp" | "sms";

export const sendChannelMessageNodeExecutor: NodeExecutor = {
  primitive: "sendChannelMessage",
  async execute(input, runContext) {
    const config = sendConfigFrom(input.node.config);
    const recipient = runContext.resolveTemplates(config.recipient).trim();
    const body = runContext.resolveTemplates(config.message).trim();
    if (!recipient) throw new Error(`${labelFor(config.kind)} senden: Empfänger fehlt.`);
    if (!body) throw new Error(`${labelFor(config.kind)} senden: Nachricht fehlt.`);
    logSendStarted(runContext.teamId, input.node, config.kind, recipient, body);
    const sent = await sendForKind(runContext.teamId, config.kind, recipient, body);
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
  kind: SendKind;
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

async function sendEmail(teamId: string, recipient: string, body: string) {
  return sendTeamEmailMessage({
    teamId,
    recipient,
    subject: "Nachricht von novooa",
    body,
    apiKey: requiredSendgridApiKey(sendgridApiKey),
  });
}

async function sendForKind(
  teamId: string,
  kind: SendKind,
  recipient: string,
  body: string,
) {
  try {
    return kind === "email"
      ? await sendEmail(teamId, recipient, body)
      : await sendMessage(teamId, kind, recipient, body);
  } catch (error) {
    logError("send_channel_node.failed", {
      teamId,
      kind,
      error: errorDetails(error),
    });
    throw error;
  }
}

async function sendMessage(
  teamId: string,
  kind: Exclude<SendKind, "email">,
  recipient: string,
  body: string,
) {
  return sendTeamChannelMessage({
    teamId,
    kind,
    recipient,
    body,
    parentAccountSid: requiredSecret(twilioAccountSid),
    authToken: requiredSecret(twilioAuthToken),
  });
}

function logSendStarted(
  teamId: string,
  node: Parameters<typeof nodeSummary>[0],
  kind: SendKind,
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

function kindFrom(value: unknown): SendKind {
  if (value === "email" || value === "whatsapp" || value === "sms") {
    return value;
  }
  return "whatsapp";
}

function labelFor(kind: SendKind): string {
  if (kind === "email") return "E-Mail";
  return kind === "whatsapp" ? "WhatsApp" : "SMS";
}

function stringFrom(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
