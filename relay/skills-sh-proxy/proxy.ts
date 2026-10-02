import {createHmac, timingSafeEqual} from "node:crypto";

export const upstreamBase = "https://skills.sh/api/v1";

/** Antwort-Header, die der Proxy unverändert weiterreicht (Rate-Limit und Cache der Runtime hängen daran). */
export const forwardedHeaders = ["content-type", "cache-control", "retry-after", "x-ratelimit-limit", "x-ratelimit-remaining", "x-ratelimit-reset"] as const;

/**
 * Die Adresse des Proxys ist fest `/api/relay` (Vercel routet `api/[...x]` in Projekten ohne Framework nur auf ein
 * Pfadsegment). Der Katalogpfad steht im Parameter `p` (z. B. `p=/skills/search`), alle übrigen Parameter gehören
 * zur Katalog-Abfrage. Weitergegeben werden nur lesende Abfragen: `/skills`, `/skills/search`, `/skills/curated`,
 * `/skills/{quelle}/{skill}` und `/skills/audit/…`. Pfade mit `..`, Doppel-Schrägstrichen oder Backslashes werden
 * abgelehnt.
 */
export function upstreamUrlFor(requestUrl: string): string | null {
  const url = new URL(requestUrl, "https://proxy.invalid");
  if (url.pathname !== "/api/relay") return null;
  const path = url.searchParams.get("p");
  if (path === null || (path !== "/skills" && !path.startsWith("/skills/"))) return null;
  if (path.includes("..") || path.includes("//") || path.includes("\\")) return null;
  const query = new URLSearchParams(url.searchParams);
  query.delete("p");
  const search = query.toString();
  return `${upstreamBase}${path}${search ? `?${search}` : ""}`;
}

export const timestampHeader = "x-novooa-timestamp";
export const signatureHeader = "x-novooa-signature";

/** Zeitfenster, in dem eine signierte Anfrage gilt (Replay-Schutz); Uhren dürfen so weit abweichen. */
export const signatureWindowMilliseconds = 60_000;

/**
 * HMAC-SHA256 über `{zeitstempel}\n{methode}\n{pfad+query}` (hex) — dieselbe Festlegung wie
 * `functions/src/features/skills/infrastructure/firebase/skills-relay-signature.ts`; beide Tests prüfen
 * denselben Vektor. Das Geheimnis teilen nur die Firebase-Funktion und dieser Proxy.
 */
export function sign(secret: string, timestamp: number, method: string, pathAndQuery: string): string {
  return createHmac("sha256", secret).update(`${timestamp}\n${method.toUpperCase()}\n${pathAndQuery}`).digest("hex");
}

/** Prüft Zeitstempel (innerhalb des Fensters) und Signatur zeitkonstant; ohne Geheimnis gilt jede Anfrage als ungültig. */
export function isValidSignature(
  secret: string | undefined,
  headers: {timestamp?: string; signature?: string},
  method: string,
  pathAndQuery: string,
  now: number,
): boolean {
  if (!secret || !headers.timestamp || !headers.signature) return false;
  const timestamp = Number(headers.timestamp);
  if (!Number.isFinite(timestamp) || Math.abs(now - timestamp) > signatureWindowMilliseconds) return false;
  const expected = Buffer.from(sign(secret, timestamp, method, pathAndQuery));
  const given = Buffer.from(headers.signature);
  return given.length === expected.length && timingSafeEqual(Uint8Array.from(given), Uint8Array.from(expected));
}
