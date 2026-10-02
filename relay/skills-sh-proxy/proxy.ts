import {timingSafeEqual} from "node:crypto";

export const upstreamBase = "https://skills.sh/api/v1";

/** Antwort-Header, die der Proxy unverändert weiterreicht (Rate-Limit und Cache der Runtime hängen daran). */
export const forwardedHeaders = ["content-type", "cache-control", "retry-after", "x-ratelimit-limit", "x-ratelimit-remaining", "x-ratelimit-reset"] as const;

/**
 * Nur lesende Katalog-Abfragen werden weitergegeben: `/skills`, `/skills/search`, `/skills/curated`,
 * `/skills/{quelle}/{skill}` und `/skills/audit/…`. Pfade mit `..` oder Doppel-Schrägstrichen werden abgelehnt.
 */
export function upstreamUrlFor(requestUrl: string): string | null {
  const url = new URL(requestUrl, "https://proxy.invalid");
  const path = url.pathname.replace(/^\/api\/v1/, "");
  if (path !== "/skills" && !path.startsWith("/skills/")) return null;
  if (path.includes("..") || path.includes("//") || path.includes("\\")) return null;
  return `${upstreamBase}${path}${url.search}`;
}

/** Prüft den Zugangsschlüssel der Runtime (`Authorization: Bearer <schlüssel>`) zeitkonstant. */
export function isAuthorized(authorization: string | undefined, expectedKey: string | undefined): boolean {
  if (!expectedKey || !authorization?.startsWith("Bearer ")) return false;
  const given = Buffer.from(authorization.slice("Bearer ".length));
  const expected = Buffer.from(expectedKey);
  return given.length === expected.length && timingSafeEqual(given, expected);
}
