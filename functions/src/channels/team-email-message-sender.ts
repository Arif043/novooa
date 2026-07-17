import {
  createOutboundMessage,
  loadSendableEmailChannel,
  markOutboundFailed,
  markOutboundSent,
} from "./send-channel-message-store.js";
import {sendViaSendgrid} from "./sendgrid-email-sender.js";

export async function sendTeamEmailMessage(input: {
  teamId: string;
  recipient: string;
  subject: string;
  body: string;
  apiKey: string;
}): Promise<{outboundId: string; providerMessageId: string; channelId: string}> {
  const channel = await loadSendableEmailChannel(input.teamId);
  const outboundInput = {
    channelId: channel.id,
    to: input.recipient,
    body: input.body,
  };
  const outboundId = await createOutboundMessage({
    channel,
    recipient: input.recipient,
    input: outboundInput,
  });
  try {
    const providerMessageId = await sendViaSendgrid({
      apiKey: input.apiKey,
      sender: channel.address,
      recipient: input.recipient,
      subject: input.subject,
      body: input.body,
    });
    await markOutboundSent({
      channel,
      outboundId,
      sid: providerMessageId,
      recipient: input.recipient,
      input: outboundInput,
    });
    return {outboundId, providerMessageId, channelId: channel.id};
  } catch (error) {
    await markOutboundFailed({channel, outboundId, error});
    throw error;
  }
}
