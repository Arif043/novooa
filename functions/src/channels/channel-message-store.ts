import {createHash} from "crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  type Firestore,
  getFirestore,
} from "firebase-admin/firestore";
import {
  type ChannelKind,
  type ChannelMessageEvent,
  channelKindFromEvent,
  messageFromEvent,
  recipientFromEvent,
  senderFromEvent,
} from "./channel-message-event.js";

export type CommunicationChannel = {
  id: string;
  teamId: string;
  kind: ChannelKind;
  address: string;
};

export async function loadCommunicationChannel(input: {
  teamId: string;
  channelId: string;
}): Promise<CommunicationChannel> {
  const snapshot = await channelReference(input).get();
  const data = snapshot.data() ?? {};
  if (!snapshot.exists || !isActiveChannel(data)) {
    throw new Error("Communication channel was not found or is inactive.");
  }
  return {
    id: snapshot.id,
    teamId: input.teamId,
    kind: channelKindFrom(data.kind),
    address: String(data.address ?? ""),
  };
}

export async function storeInboundChannelMessage(input: {
  channel: CommunicationChannel;
  event: ChannelMessageEvent;
}): Promise<boolean> {
  const db = database();
  const conversationId = conversationIdFrom(senderFromEvent(input.event));
  const references = messageReferences(db, input, conversationId);
  return db.runTransaction(async (transaction) => {
    const existing = await transaction.get(references.message);
    if (existing.exists) return false;
    transaction.set(references.conversation, conversationDocument(input), {
      merge: true,
    });
    transaction.set(references.message, messageDocument(input));
    return true;
  });
}

function isActiveChannel(data: Record<string, unknown>): boolean {
  const capabilities = data.capabilities;
  return data.status === "active" &&
    isRecord(capabilities) &&
    capabilities.inbound === true;
}

function channelKindFrom(value: unknown): ChannelKind {
  if (value === "whatsapp" || value === "sms" || value === "email") {
    return value;
  }
  throw new Error("Unsupported communication channel kind.");
}

function messageReferences(
  db: Firestore,
  input: {
    channel: CommunicationChannel;
    event: ChannelMessageEvent;
  },
  conversationId: string,
) {
  const conversation = db
    .collection("teams")
    .doc(input.channel.teamId)
    .collection("inboxes")
    .doc(input.channel.id)
    .collection("conversations")
    .doc(conversationId);
  return {
    conversation,
    message: conversation.collection("messages")
      .doc(input.event.providerMessageId),
  };
}

function conversationDocument(input: {
  channel: CommunicationChannel;
  event: ChannelMessageEvent;
}) {
  const sender = senderFromEvent(input.event);
  const message = messageFromEvent(input.event);
  return {
    id: conversationIdFrom(sender),
    channelId: input.channel.id,
    channel: channelKindFromEvent(input.event),
    eventType: input.event.type,
    externalContactId: sender,
    lastMessageAt: FieldValue.serverTimestamp(),
    lastMessagePreview: message.slice(0, 160),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function messageDocument(input: {
  event: ChannelMessageEvent;
}) {
  const event = input.event;
  return {
    id: input.event.providerMessageId,
    provider: input.event.provider,
    providerMessageId: input.event.providerMessageId,
    direction: "inbound",
    channel: channelKindFromEvent(event),
    eventType: event.type,
    from: senderFromEvent(event),
    to: recipientFromEvent(event),
    text: messageFromEvent(event),
    ...(event.type === "emailReceived" ?
      {subject: event.subject} :
      {media: event.media}),
    event,
    raw: event.raw,
    createdAt: FieldValue.serverTimestamp(),
  };
}

function channelReference(input: {teamId: string; channelId: string}) {
  return database()
    .collection("teams")
    .doc(input.teamId)
    .collection("communicationChannels")
    .doc(input.channelId);
}

function conversationIdFrom(address: string): string {
  return createHash("sha256").update(address).digest("hex").slice(0, 32);
}

function database(): Firestore {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
