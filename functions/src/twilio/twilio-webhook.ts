import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
import {logError, logInfo} from "../task-runner/structured-logger.js";
import {twilioMessageEventFrom} from "./twilio-message-event.js";
import {
  formFieldsFromRequest,
  channelIdFromRequest,
  publicRequestUrl,
  teamIdFromRequest,
} from "./twilio-request.js";
import {isValidTwilioSignature} from "./twilio-signature.js";
import {loadTwilioCommunicationChannel} from "./twilio-message-store.js";
import {channelMessageEventFromTwilio} from "../channels/channel-message-event.js";
import {storeInboundChannelMessage} from "../channels/channel-message-store.js";
import {dispatchChannelMessageTriggers} from "../channels/channel-trigger-dispatcher.js";

const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");

export const twilioWebhook = onRequest(
  {secrets: [twilioAuthToken]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).send("Method Not Allowed");
      return;
    }
    try {
      const fields = formFieldsFromRequest(request);
      verifyRequest(request.get("x-twilio-signature"), request, fields);
      const event = twilioMessageEventFrom(fields);
      const teamId = teamIdFromRequest(request);
      const channelId = channelIdFromRequest(request);
      const channel = await loadTwilioCommunicationChannel({
        teamId,
        channelId,
        event,
      });
      const channelEvent = channelMessageEventFromTwilio(event);
      const created = await storeInboundChannelMessage({
        channel,
        event: channelEvent,
      });
      if (created) {
        await dispatchChannelMessageTriggers({
          teamId,
          channelId,
          event: channelEvent,
        });
      }
      logInfo("twilio_message.received", {teamId, channelId, created});
      response.type("text/xml").status(200).send("<Response></Response>");
    } catch (error) {
      logError("twilio_message.failed", {message: errorMessage(error)});
      response.status(400).send(errorMessage(error));
    }
  },
);

function verifyRequest(
  signature: string | undefined,
  request: Parameters<typeof publicRequestUrl>[0],
  fields: Record<string, string>,
): void {
  const authToken = twilioAuthToken.value().trim();
  if (authToken.length === 0 && process.env.FUNCTIONS_EMULATOR === "true") {
    return;
  }
  if (authToken.length === 0) throw new Error("TWILIO_AUTH_TOKEN is required.");
  const valid = isValidTwilioSignature({
    authToken,
    requestUrl: publicRequestUrl(request),
    fields,
    signature,
  });
  if (!valid) throw new Error("Invalid Twilio signature.");
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Twilio webhook failed.";
}
