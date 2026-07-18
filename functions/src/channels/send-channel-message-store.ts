import {getFirestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {initializeAdminApp} from "../team-context.js";
import {logError, logInfo} from "../task-runner/structured-logger.js";
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
  kind: "whatsapp" | "sms" | "email";
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

export async function loadSendableChannelByKind(
  teamId: string,
  kind: "whatsapp" | "sms",
): Promise<SendableChannel> {
  initializeAdminApp();
  const snapshot = await getFirestore()
    .collection("teams")
    .doc(teamId)
    .collection("communicationChannels")
    .get();
  logInfo("send_channel_store.channels_loaded", {
    teamId,
    requestedKind: kind,
    channelCount: snapshot.size,
  });
  const channel = snapshot.docs.find((document) => {
    const data = document.data();
    return data.kind === kind && isSendableTwilioChannel(data);
  });
  if (!channel) {
    logError("send_channel_store.no_sendable_channel", {
      teamId,
      requestedKind: kind,
      candidates: snapshot.docs.map(channelCandidate),
    });
    throw new HttpsError("failed-precondition", "No sendable channel found.");
  }
  const data = channel.data();
  return {
    id: channel.id,
    teamId,
    kind: channelKindFrom(data.kind),
    address: stringFrom(data.address),
  };
}

export async function loadSendableEmailChannel(
  teamId: string,
): Promise<SendableChannel> {
  initializeAdminApp();
  const snapshot = await getFirestore()
    .collection("teams")
    .doc(teamId)
    .collection("communicationChannels")
    .get();
  const channel = snapshot.docs.find((document) => {
    const data = document.data();
    return data.kind === "email" && isSendableEmailChannel(data);
  });
  if (!channel) {
    throw new HttpsError("failed-precondition", "No sendable email channel found.");
  }
  const data = channel.data();
  return {
    id: channel.id,
    teamId,
    kind: "email",
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
    sentDocument(input.sid, providerFor(input.channel.kind)),
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

function channelCandidate(document: {
  id: string;
  data(): Record<string, unknown>;
}) {
  const data = document.data();
  const capabilities = isRecord(data.capabilities) ? data.capabilities : {};
  return {
    id: document.id,
    kind: data.kind,
    provider: data.provider,
    status: data.status,
    outbound: capabilities.outbound,
  };
}

function channelKindFrom(value: unknown): "whatsapp" | "sms" | "email" {
  if (value === "whatsapp" || value === "sms" || value === "email") return value;
  throw new HttpsError("failed-precondition", "Unsupported channel kind.");
}

function isSendableEmailChannel(data: Record<string, unknown>): boolean {
  const capabilities = data.capabilities;
  return (
    data.provider === "sendgrid" &&
    data.status === "active" &&
    isRecord(capabilities) &&
    capabilities.outbound === true
  );
}

function providerFor(kind: SendableChannel["kind"]): string {
  return kind === "email" ? "sendgrid" : "twilio";
}

function stringFrom(value: unknown): string {
  if (typeof value === "string" && value.trim()) return value.trim();
  throw new HttpsError("failed-precondition", "Channel address is missing.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
