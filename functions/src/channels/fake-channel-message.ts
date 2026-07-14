import {randomUUID} from "crypto";
import {z} from "genkit";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import type {
  ChannelKind,
  ChannelMessageEvent,
} from "./channel-message-event.js";
import {
  loadCommunicationChannel,
  storeInboundChannelMessage,
} from "./channel-message-store.js";
import {dispatchChannelMessageTriggers} from "./channel-trigger-dispatcher.js";

const fakeChannelMessageInputSchema = z.object({
  channelId: z.string().min(1),
  body: z.string().min(1).max(4000).default("Testnachricht aus Syscat"),
  from: z.string().min(1).max(240).optional(),
  subject: z.string().max(240).optional(),
});

export const dispatchFakeChannelMessage = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Auth is required.");
  const input = fakeChannelMessageInputSchema.parse(request.data);
  const teamId = `personal_${uid}`;
  const channel = await loadCommunicationChannel({teamId, channelId: input.channelId});
  const event = fakeEventFor(channel.kind, channel.address, input);
  const created = await storeInboundChannelMessage({channel, event});
  if (created) {
    await dispatchChannelMessageTriggers({teamId, channelId: channel.id, event});
  }
  return {channelId: channel.id, messageId: event.providerMessageId, created};
});

function fakeEventFor(
  channel: ChannelKind,
  to: string,
  input: z.infer<typeof fakeChannelMessageInputSchema>,
): ChannelMessageEvent {
  const from = input.from?.trim() || defaultSenderFor(channel);
  const base = {
    provider: "fake" as const,
    providerMessageId: `fake_${randomUUID()}`,
    receivedAt: new Date().toISOString(),
    raw: {source: "syscat_fake_channel_message"},
  };
  if (channel === "email") {
    return {
      ...base,
      type: "emailReceived",
      senderEmail: from,
      recipientEmail: to,
      subject: input.subject?.trim() || "Testnachricht",
      message: input.body,
    };
  }
  if (channel === "whatsapp") {
    return {
      ...base,
      type: "whatsappMessageReceived",
      senderPhoneNumber: from,
      recipientPhoneNumber: phoneNumberFrom(to),
      message: input.body,
      media: [],
    };
  }
  return {
    ...base,
    type: "smsMessageReceived",
    senderPhoneNumber: from,
    recipientPhoneNumber: to,
    message: input.body,
    media: [],
  };
}

function defaultSenderFor(channel: ChannelKind): string {
  if (channel === "email") return "demo@example.com";
  return "+491700000001";
}

function phoneNumberFrom(value: string): string {
  return value.startsWith("whatsapp:") ? value.slice("whatsapp:".length) : value;
}
