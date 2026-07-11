import {createHmac, timingSafeEqual} from "crypto";

export function isValidTwilioSignature(input: {
  authToken: string;
  requestUrl: string;
  fields: Record<string, string>;
  signature: string | undefined;
}): boolean {
  if (!input.signature) return false;
  const expected = expectedSignature(input);
  const expectedBuffer = Buffer.from(expected);
  const actualBuffer = Buffer.from(input.signature);
  if (expectedBuffer.length !== actualBuffer.length) return false;
  return timingSafeEqual(expectedBuffer, actualBuffer);
}

function expectedSignature(input: {
  authToken: string;
  requestUrl: string;
  fields: Record<string, string>;
}): string {
  const payload = Object.keys(input.fields)
    .sort()
    .reduce((value, key) => `${value}${key}${input.fields[key]}`, input.requestUrl);
  return createHmac("sha1", input.authToken).update(payload).digest("base64");
}
