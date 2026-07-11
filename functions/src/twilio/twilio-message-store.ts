import {createHash} from "crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  type Firestore,
  getFirestore,
} from "firebase-admin/firestore";
import type {TwilioMessageEvent} from "./twilio-message-event.js";

export type TwilioIntegration = {
  id: string;
  teamId: string;
};

export async function loadTwilioIntegration(input: {
  teamId: string;
  integrationId: string;
  event: TwilioMessageEvent;
}): Promise<TwilioIntegration> {
  const snapshot = await database()
    .collection("teams")
    .doc(input.teamId)
    .collection("integrations")
    .doc(input.integrationId)
    .get();
  const data = snapshot.data() ?? {};
  if (!snapshot.exists || !isActiveTwilioIntegration(data, input.event)) {
    throw new Error("Twilio integration was not found or is inactive.");
  }
  return {id: snapshot.id, teamId: input.teamId};
}

export async function storeInboundTwilioMessage(input: {
  integration: TwilioIntegration;
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

function isActiveTwilioIntegration(
  data: Record<string, unknown>,
  event: TwilioMessageEvent,
): boolean {
  return data.provider === "twilio" &&
    data.status === "active" &&
    data.accountSid === event.accountSid &&
    data.externalAddress === event.to;
}

function messageReferences(
  db: Firestore,
  input: {
    integration: TwilioIntegration;
    event: TwilioMessageEvent;
  },
  conversationId: string,
) {
  const conversation = db
    .collection("teams")
    .doc(input.integration.teamId)
    .collection("inboxes")
    .doc(input.integration.id)
    .collection("conversations")
    .doc(conversationId);
  return {
    conversation,
    message: conversation.collection("messages").doc(input.event.messageSid),
  };
}

function conversationDocument(input: {
  integration: TwilioIntegration;
  event: TwilioMessageEvent;
}) {
  return {
    id: conversationIdFrom(input.event.from),
    integrationId: input.integration.id,
    channel: input.event.channel,
    externalContactId: input.event.from,
    lastMessageAt: FieldValue.serverTimestamp(),
    lastMessagePreview: input.event.body.slice(0, 160),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function messageDocument(input: {
  integration: TwilioIntegration;
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
