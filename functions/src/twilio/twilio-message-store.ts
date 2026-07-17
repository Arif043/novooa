import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {logError} from "../task-runner/structured-logger.js";
import type {TwilioMessageEvent} from "./twilio-message-event.js";

export type TwilioCommunicationChannel = {
  id: string;
  teamId: string;
  kind: "whatsapp" | "sms";
  address: string;
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
    logChannelMismatch({
      teamId: input.teamId,
      channelId: input.channelId,
      exists: snapshot.exists,
      data,
      event: input.event,
    });
    throw new Error("Twilio communication channel was not found or is inactive.");
  }
  return {
    id: snapshot.id,
    teamId: input.teamId,
    kind: input.event.channel,
    address: input.event.to,
  };
}

function isActiveTwilioChannel(
  data: Record<string, unknown>,
  event: TwilioMessageEvent,
): boolean {
  return data.provider === "twilio" &&
    data.status === "active" &&
    data.kind === event.channel &&
    data.address === event.to;
}

function logChannelMismatch(input: {
  teamId: string;
  channelId: string;
  exists: boolean;
  data: Record<string, unknown>;
  event: TwilioMessageEvent;
}): void {
  logError("twilio_channel.match_failed", {
    teamId: input.teamId,
    channelId: input.channelId,
    exists: input.exists,
    storedProvider: stringValue(input.data.provider),
    storedStatus: stringValue(input.data.status),
    storedKind: stringValue(input.data.kind),
    storedAddress: stringValue(input.data.address),
    incomingKind: input.event.channel,
    incomingTo: input.event.to,
  });
}

function stringValue(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

function database() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}
