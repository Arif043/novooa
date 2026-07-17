import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "genkit";
import {currentTeamIdForUid} from "../team-context.js";
import {logError, logInfo} from "../task-runner/structured-logger.js";
import {
  type SendChannelMessageInput,
} from "./send-channel-message-store.js";
import {sendTeamChannelMessage} from "./team-channel-message-sender.js";
import {
  requiredSecret,
  twilioAccountSid,
  twilioAuthToken,
} from "./twilio-secrets.js";

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
    const parentAccountSid = requiredSecret(twilioAccountSid);
    const authToken = requiredSecret(twilioAuthToken);
    try {
      const sent = await sendTeamChannelMessage({
        teamId,
        channelId: input.channelId,
        kind: "sms",
        recipient: input.to,
        body: input.body,
        parentAccountSid,
        authToken,
      });
      logInfo("channel_message.sent", {
        teamId,
        channelId: sent.channelId,
        sid: sent.providerMessageId,
      });
      return {
        messageId: sent.outboundId,
        providerMessageId: sent.providerMessageId,
        status: "sent",
      };
    } catch (error) {
      logSendFailure({teamId, channelId: input.channelId, error});
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
