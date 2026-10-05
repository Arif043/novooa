import {createHmac, timingSafeEqual} from "node:crypto";
import {type WebhookVerification} from "../../../scheduling/domain/entities/webhook-config.js";

type Hmac = Extract<WebhookVerification, {kind: "hmac"}>;

/** Prüft die Signatur über die **Rohbytes** des Bodys; ein neu serialisiertes JSON würde sie nie treffen. */
export function webhookSignatureMatches(
  verification: Hmac, secret: string, rawBody: Buffer, headerValue: string | undefined,
): boolean {
  if (headerValue === undefined) return false;
  const received = headerValue.trim();
  if (!received.startsWith(verification.prefix)) return false;
  const given = decode(received.slice(verification.prefix.length), verification.encoding);
  const expected = createHmac(verification.algorithm, secret).update(rawBody).digest();
  return given !== null && given.length === expected.length && timingSafeEqual(given, expected);
}

function decode(value: string, encoding: Hmac["encoding"]): Buffer | null {
  const pattern = encoding === "hex" ? /^[0-9a-fA-F]*$/ : /^[A-Za-z0-9+/_-]*={0,2}$/;
  if (!pattern.test(value)) return null;
  return Buffer.from(value, encoding === "hex" ? "hex" : "base64");
}
