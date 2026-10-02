import {createHmac, timingSafeEqual} from "node:crypto";

export const timestampHeader = "x-novooa-timestamp";
export const signatureHeader = "x-novooa-signature";

/** Zeitfenster, in dem eine signierte Anfrage gilt (Replay-Schutz); Uhren dürfen so weit abweichen. */
export const signatureWindowMilliseconds = 60_000;

/**
 * HMAC-SHA256 über `{zeitstempel}\n{methode}\n{pfad+query}` (hex). Die Server-Umgebungen Firebase und
 * Vercel teilen das Geheimnis; es liegt nie bei der Runtime. Dieselbe Festlegung prüft
 * `relay/skills-sh-proxy/proxy.ts`.
 */
export function signSkillsRelayRequest(secret: string, timestamp: number, method: string, pathAndQuery: string): string {
  return createHmac("sha256", secret).update(`${timestamp}\n${method.toUpperCase()}\n${pathAndQuery}`).digest("hex");
}

export function isValidSkillsRelaySignature(
  secret: string, timestamp: number, method: string, pathAndQuery: string, signature: string, now: number,
): boolean {
  if (!Number.isFinite(timestamp) || Math.abs(now - timestamp) > signatureWindowMilliseconds) return false;
  const expected = Buffer.from(signSkillsRelayRequest(secret, timestamp, method, pathAndQuery));
  const given = Buffer.from(signature);
  return given.length === expected.length && timingSafeEqual(given, expected);
}
