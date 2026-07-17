import {createHash} from "crypto";
import {
  FieldValue,
  getFirestore,
  type WriteBatch,
} from "firebase-admin/firestore";
import {
  type SendChannelMessageInput,
  type SendableChannel,
} from "./send-channel-message-store.js";
import {addressFor} from "./channel-address.js";

export function outboundMessages(channel: SendableChannel) {
  return getFirestore()
    .collection("teams")
    .doc(channel.teamId)
    .collection("outboundMessages");
}

export function outboundDocument(input: {
  channel: SendableChannel;
  recipient: string;
  input: SendChannelMessageInput;
}) {
  return {
    channelId: input.channel.id,
    channel: input.channel.kind,
    direction: "outbound",
    to: input.recipient,
    from: addressFor(input.channel.kind, input.channel.address),
    text: input.input.body.trim(),
    status: "sending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function sentDocument(providerMessageId: string) {
  return {
    status: "sent",
    provider: "twilio",
    providerMessageId,
    sentAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function failedDocument(error: unknown) {
  return {
    status: "failed",
    errorMessage: errorMessage(error),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function addConversationWrites(
  batch: WriteBatch,
  input: {
    channel: SendableChannel;
    sid: string;
    recipient: string;
    input: SendChannelMessageInput;
  },
): void {
  const conversation = conversationReference(input.channel, input.recipient);
  batch.set(conversation, conversationDocument(input), {merge: true});
  batch.set(
    conversation.collection("messages").doc(input.sid),
    messageDocument(input),
  );
}

function conversationReference(channel: SendableChannel, recipient: string) {
  return getFirestore()
    .collection("teams")
    .doc(channel.teamId)
    .collection("inboxes")
    .doc(channel.id)
    .collection("conversations")
    .doc(conversationIdFrom(recipient));
}

function conversationDocument(input: {
  channel: SendableChannel;
  recipient: string;
  input: SendChannelMessageInput;
}) {
  return {
    id: conversationIdFrom(input.recipient),
    channelId: input.channel.id,
    channel: input.channel.kind,
    externalContactId: input.recipient,
    lastMessageAt: FieldValue.serverTimestamp(),
    lastMessagePreview: input.input.body.trim().slice(0, 160),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function messageDocument(input: {
  channel: SendableChannel;
  sid: string;
  recipient: string;
  input: SendChannelMessageInput;
}) {
  return {
    id: input.sid,
    provider: "twilio",
    providerMessageId: input.sid,
    direction: "outbound",
    channel: input.channel.kind,
    from: addressFor(input.channel.kind, input.channel.address),
    to: input.recipient,
    text: input.input.body.trim(),
    createdAt: FieldValue.serverTimestamp(),
  };
}

function conversationIdFrom(address: string): string {
  return createHash("sha256").update(address).digest("hex").slice(0, 32);
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Unknown send error.";
}
