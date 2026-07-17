import {getFirestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {initializeAdminApp} from "../team-context.js";
import {
  addConversationWrites,
  failedDocument,
  outboundDocument,
  outboundMessages,
  sentDocument,
} from "./send-channel-message-documents.js";
export {addressFor} from "./channel-address.js";

export type SendChannelMessageInput = {
  channelId: string;
  to: string;
  body: string;
};

export type SendableChannel = {
  id: string;
  teamId: string;
  kind: "whatsapp" | "sms";
  address: string;
};

export async function loadSendableChannel(
  teamId: string,
  channelId: string,
): Promise<SendableChannel> {
  initializeAdminApp();
  const snapshot = await getFirestore()
    .collection("teams")
    .doc(teamId)
    .collection("communicationChannels")
    .doc(channelId)
    .get();
  const data = snapshot.data() ?? {};
  if (!snapshot.exists || !isSendableTwilioChannel(data)) {
    throw new HttpsError("failed-precondition", "Channel cannot send messages.");
  }
  return {
    id: snapshot.id,
    teamId,
    kind: channelKindFrom(data.kind),
    address: stringFrom(data.address),
  };
}

export async function createOutboundMessage(input: {
  channel: SendableChannel;
  recipient: string;
  input: SendChannelMessageInput;
}): Promise<string> {
  const reference = outboundMessages(input.channel).doc();
  await reference.set(outboundDocument(input));
  return reference.id;
}

export async function markOutboundSent(input: {
  channel: SendableChannel;
  outboundId: string;
  sid: string;
  recipient: string;
  input: SendChannelMessageInput;
}): Promise<void> {
  const batch = getFirestore().batch();
  batch.set(
    outboundMessages(input.channel).doc(input.outboundId),
    sentDocument(input.sid),
    {merge: true},
  );
  addConversationWrites(batch, input);
  await batch.commit();
}

export async function markOutboundFailed(input: {
  channel: SendableChannel;
  outboundId: string;
  error: unknown;
}): Promise<void> {
  await outboundMessages(input.channel)
    .doc(input.outboundId)
    .set(failedDocument(input.error), {merge: true});
}

function isSendableTwilioChannel(data: Record<string, unknown>): boolean {
  const capabilities = data.capabilities;
  return (
    data.provider === "twilio" &&
    data.status === "active" &&
    isRecord(capabilities) &&
    capabilities.outbound === true &&
    (data.kind === "sms" || data.kind === "whatsapp")
  );
}

function channelKindFrom(value: unknown): "whatsapp" | "sms" {
  if (value === "whatsapp" || value === "sms") return value;
  throw new HttpsError("failed-precondition", "Unsupported channel kind.");
}

function stringFrom(value: unknown): string {
  if (typeof value === "string" && value.trim()) return value.trim();
  throw new HttpsError("failed-precondition", "Channel address is missing.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
