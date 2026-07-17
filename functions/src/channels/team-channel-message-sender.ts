import {
  addressFor,
  createOutboundMessage,
  loadSendableChannel,
  loadSendableChannelByKind,
} from "./send-channel-message-store.js";
import {markOutboundFailed, markOutboundSent} from "./send-channel-message-store.js";
import {ensureTeamTwilioSubaccount} from "./twilio-team-subaccount.js";
import {sendViaTwilio} from "./twilio-channel-sender.js";

export type OutboundChannelKind = "whatsapp" | "sms";

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
  const outboundId = await createOutboundMessage({
    channel,
    recipient,
    input: {channelId: channel.id, to: recipient, body: input.body},
  });
  try {
    const subaccountSid = await ensureTeamTwilioSubaccount({
      teamId: input.teamId,
      parentAccountSid: input.parentAccountSid,
      authToken: input.authToken,
    });
    const providerMessageId = await sendViaTwilio({
      parentAccountSid: input.parentAccountSid,
      authToken: input.authToken,
      subaccountSid,
      sender,
      recipient,
      body: input.body,
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
    throw error;
  }
}
