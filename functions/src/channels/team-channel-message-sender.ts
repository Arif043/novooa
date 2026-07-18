import {
  addressFor,
  createOutboundMessage,
  loadSendableChannel,
  loadSendableChannelByKind,
} from "./send-channel-message-store.js";
import {markOutboundFailed, markOutboundSent} from "./send-channel-message-store.js";
import {ensureTeamTwilioSubaccount} from "./twilio-team-subaccount.js";
import {sendViaTwilio} from "./twilio-channel-sender.js";
import {errorDetails, logError, logInfo, textSummary} from "../task-runner/structured-logger.js";

export type OutboundChannelKind = "whatsapp" | "sms";

const twilioWhatsappSandboxSender = "whatsapp:+14155238886";

export async function sendTeamChannelMessage(input: {
  teamId: string;
  channelId?: string;
  kind: OutboundChannelKind;
  recipient: string;
  body: string;
  parentAccountSid: string;
  authToken: string;
}): Promise<{outboundId: string; providerMessageId: string; channelId: string}> {
  const channel = input.channelId === undefined
    ? await loadSendableChannelByKind(input.teamId, input.kind)
    : await loadSendableChannel(input.teamId, input.channelId);
  const recipient = addressFor(channel.kind, input.recipient);
  const sender = addressFor(channel.kind, channel.address);
  logInfo("team_channel_send.channel_selected", {
    teamId: input.teamId,
    channelId: channel.id,
    kind: channel.kind,
    senderLength: sender.length,
    recipientLength: recipient.length,
    ...textSummary(input.body, "message"),
  });
  const outboundId = await createOutboundMessage({
    channel,
    recipient,
    input: {channelId: channel.id, to: recipient, body: input.body},
  });
  logInfo("team_channel_send.outbound_created", {
    teamId: input.teamId,
    channelId: channel.id,
    outboundId,
  });
  try {
    const account = await twilioAccountFor(input, sender);
    logInfo("team_channel_send.account_selected", {
      teamId: input.teamId,
      channelId: channel.id,
      outboundId,
      mode: account.mode,
      subaccountSid: account.subaccountSid ?? null,
    });
    const providerMessageId = await sendViaTwilio({
      parentAccountSid: input.parentAccountSid,
      authToken: input.authToken,
      subaccountSid: account.subaccountSid,
      sender,
      recipient,
      body: input.body,
    });
    logInfo("team_channel_send.provider_sent", {
      teamId: input.teamId,
      channelId: channel.id,
      outboundId,
      providerMessageId,
    });
    await markOutboundSent({
      channel,
      outboundId,
      sid: providerMessageId,
      recipient,
      input: {channelId: channel.id, to: recipient, body: input.body},
    });
    return {outboundId, providerMessageId, channelId: channel.id};
  } catch (error) {
    await markOutboundFailed({channel, outboundId, error});
    logError("team_channel_send.failed", {
      teamId: input.teamId,
      channelId: channel.id,
      outboundId,
      error: errorDetails(error),
    });
    throw error;
  }
}

async function twilioAccountFor(
  input: {
    teamId: string;
    parentAccountSid: string;
    authToken: string;
  },
  sender: string,
): Promise<{mode: "parent" | "subaccount"; subaccountSid?: string}> {
  if (sender === twilioWhatsappSandboxSender) return {mode: "parent"};
  const subaccountSid = await ensureTeamTwilioSubaccount(input);
  return {mode: "subaccount", subaccountSid};
}
