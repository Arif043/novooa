import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "genkit";
import {currentTeamIdForUid} from "../team-context.js";
import {logError, logInfo} from "../task-runner/structured-logger.js";
import {
  addressFor,
  createOutboundMessage,
  loadSendableChannel,
  markOutboundFailed,
  markOutboundSent,
  type SendChannelMessageInput,
} from "./send-channel-message-store.js";
import {sendViaTwilio} from "./twilio-channel-sender.js";
import {ensureTeamTwilioSubaccount} from "./twilio-team-subaccount.js";

const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");

const sendChannelMessageInputSchema = z.object({
  channelId: z.string().min(1).max(160),
  to: z.string().min(3).max(160),
  body: z.string().min(1).max(4000),
});

export const sendChannelMessage = onCall(
  {secrets: [twilioAccountSid, twilioAuthToken]},
  async (request) => {
    const uid = authenticatedUid(request.auth?.uid);
    const input = inputFrom(request.data);
    const teamId = await currentTeamIdForUid(uid);
    const channel = await loadSendableChannel(teamId, input.channelId);
    const recipient = addressFor(channel.kind, input.to);
    const sender = addressFor(channel.kind, channel.address);
    const outboundId = await createOutboundMessage({channel, recipient, input});
    const parentAccountSid = requiredSecret(twilioAccountSid);
    const authToken = requiredSecret(twilioAuthToken);
    try {
      const subaccountSid = await ensureTeamTwilioSubaccount({
        teamId,
        parentAccountSid,
        authToken,
      });
      const sid = await sendViaTwilio({
        parentAccountSid,
        authToken,
        subaccountSid,
        sender,
        recipient,
        body: input.body,
      });
      await markOutboundSent({channel, outboundId, sid, recipient, input});
      logInfo("channel_message.sent", {teamId, channelId: channel.id, sid});
      return {messageId: outboundId, providerMessageId: sid, status: "sent"};
    } catch (error) {
      await markOutboundFailed({channel, outboundId, error});
      logSendFailure({teamId, channelId: channel.id, error});
      throw new HttpsError("internal", "Nachricht konnte nicht gesendet werden.");
    }
  },
);

function authenticatedUid(uid: string | undefined): string {
  if (!uid) throw new HttpsError("unauthenticated", "Auth is required.");
  return uid;
}

function inputFrom(data: unknown): SendChannelMessageInput {
  try {
    return sendChannelMessageInputSchema.parse(data);
  } catch {
    throw new HttpsError("invalid-argument", "Invalid message input.");
  }
}

function requiredSecret(secret: {value(): string}): string {
  const value = secret.value().trim();
  if (value) return value;
  throw new HttpsError("failed-precondition", "Twilio credentials are missing.");
}

function logSendFailure(input: {
  teamId: string;
  channelId: string;
  error: unknown;
}): void {
  logError("channel_message.send_failed", {
    teamId: input.teamId,
    channelId: input.channelId,
    errorMessage: errorMessage(input.error),
  });
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Unknown send error.";
}
