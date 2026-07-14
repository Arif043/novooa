import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
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
    data.accountSid === event.accountSid &&
    data.address === event.to;
}

function database() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}
