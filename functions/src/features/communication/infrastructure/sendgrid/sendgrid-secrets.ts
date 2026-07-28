import {defineSecret} from "firebase-functions/params";
import {HttpsError} from "firebase-functions/v2/https";

export const sendgridApiKey = defineSecret("SENDGRID_API_KEY");

export function requiredSendgridApiKey(secret: {value(): string}): string {
  const value = secret.value().trim();
  if (value) return value;
  throw new HttpsError("failed-precondition", "SendGrid credentials are missing.");
}
