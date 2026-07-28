import {defineSecret} from "firebase-functions/params";
import {HttpsError} from "firebase-functions/v2/https";

export const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
export const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");

export function requiredSecret(secret: {value(): string}): string {
  const value = secret.value().trim();
  if (value) return value;
  throw new HttpsError("failed-precondition", "Twilio credentials are missing.");
}
