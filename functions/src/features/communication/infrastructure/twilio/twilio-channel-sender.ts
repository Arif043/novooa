import twilio from "twilio";
import {logError, logInfo, textSummary} from "../../../../shared/logging/logger.js";

export async function sendViaTwilio(input: {
  parentAccountSid: string;
  authToken: string;
  subaccountSid?: string;
  sender: string;
  recipient: string;
  body: string;
}): Promise<string> {
  const client = twilio(input.parentAccountSid, input.authToken, clientOptions(input));
  logInfo("twilio_send.started", {
    accountMode: input.subaccountSid ? "subaccount" : "parent",
    subaccountSid: input.subaccountSid ?? null,
    senderLength: input.sender.length,
    recipientLength: input.recipient.length,
    ...textSummary(input.body, "message"),
  });
  try {
    const message = await client.messages.create({
      from: input.sender,
      to: input.recipient,
      body: input.body.trim(),
    });
    logInfo("twilio_send.sent", {
      sid: message.sid,
      status: message.status,
      direction: message.direction,
    });
    return message.sid;
  } catch (error) {
    logError("twilio_send.failed", twilioErrorDetails(error));
    throw error;
  }
}

function clientOptions(input: {subaccountSid?: string}) {
  return input.subaccountSid ? {accountSid: input.subaccountSid} : undefined;
}

function twilioErrorDetails(error: unknown): Record<string, unknown> {
  if (!isRecord(error)) return {message: String(error)};
  return {
    name: error.name,
    message: error.message,
    code: error.code,
    status: error.status,
    moreInfo: error.moreInfo,
    details: error.details,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
