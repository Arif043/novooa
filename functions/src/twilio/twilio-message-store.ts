import {createHash} from "crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  type Firestore,
  getFirestore,
} from "firebase-admin/firestore";
import type {TwilioMessageEvent} from "./twilio-message-event.js";

export type TwilioCommunicationChannel = {
  id: string;
  teamId: string;
};

export async function loadTwilioCommunicationChannel(input: {
  teamId: string;
  channelId: string;
  event: TwilioMessageEvent;
}): Promise<TwilioCommunicationChannel> {
  const snapshot = await database()
    .collection("teams")
    .doc(input.teamId)
    .collection("communicationChannels")
    .doc(input.channelId)
    .get();
  const data = snapshot.data() ?? {};
  if (!snapshot.exists || !isActiveTwilioChannel(data, input.event)) {
    throw new Error("Twilio communication channel was not found or is inactive.");
  }
  return {id: snapshot.id, teamId: input.teamId};
}

export async function storeInboundTwilioMessage(input: {
  channel: TwilioCommunicationChannel;
  event: TwilioMessageEvent;
}): Promise<boolean> {
  const db = database();
  const conversationId = conversationIdFrom(input.event.from);
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

function isActiveTwilioChannel(
  data: Record<string, unknown>,
  event: TwilioMessageEvent,
): boolean {
  return data.provider === "twilio" &&
    data.status === "active" &&
    data.kind === event.channel &&
    data.accountSid === event.accountSid &&
    data.address === event.to;
}

function messageReferences(
  db: Firestore,
  input: {
    channel: TwilioCommunicationChannel;
    event: TwilioMessageEvent;
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
    message: conversation.collection("messages").doc(input.event.messageSid),
  };
}

function conversationDocument(input: {
  channel: TwilioCommunicationChannel;
  event: TwilioMessageEvent;
}) {
  return {
    id: conversationIdFrom(input.event.from),
    channelId: input.channel.id,
    channel: input.event.channel,
    externalContactId: input.event.from,
    lastMessageAt: FieldValue.serverTimestamp(),
    lastMessagePreview: input.event.body.slice(0, 160),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function messageDocument(input: {
  channel: TwilioCommunicationChannel;
  event: TwilioMessageEvent;
}) {
  return {
    id: input.event.messageSid,
    provider: "twilio",
    providerMessageId: input.event.messageSid,
    direction: "inbound",
    channel: input.event.channel,
    from: input.event.from,
    to: input.event.to,
    text: input.event.body,
    media: input.event.media,
    raw: input.event.raw,
    createdAt: FieldValue.serverTimestamp(),
  };
}

function conversationIdFrom(address: string): string {
  return createHash("sha256").update(address).digest("hex").slice(0, 32);
}

function database(): Firestore {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}
