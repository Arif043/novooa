/** Eine Katalog-Anfrage, die das Relay an skills.sh weitergibt. */
export type SkillRelayRequest = {
  /** Pfad unterhalb von `/api/v1`, z. B. `/skills/search`. Segmente sind bereits URL-kodiert. */
  path: string;
  query: Record<string, string>;
};

/** Ein Fehler in der Anfrage der Runtime (nicht erlaubter Pfad oder Parameter). */
export class SkillRelayRequestError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SkillRelayRequestError";
  }
}

/** Die Lizenz hat ihr Kontingent verbraucht; `retryAfterSeconds` sagt, wann wieder ein Token frei ist. */
export class SkillRelayRateLimitedError extends Error {
  constructor(readonly retryAfterSeconds: number) {
    super(`Zu viele Anfragen. Bitte in ${retryAfterSeconds} Sekunden erneut versuchen.`);
    this.name = "SkillRelayRateLimitedError";
  }
}

const allowedQueryParameters: ReadonlySet<string> = new Set(["q", "limit", "owner", "view", "page", "per_page"]);
const segmentPattern = /^[A-Za-z0-9._~%-]+$/;
const maximumSegments = 8;
const maximumPathLength = 300;
const maximumValueLength = 200;

/**
 * Das Relay gibt nur lesende Katalog-Abfragen weiter: `/skills`, `/skills/search`, `/skills/curated`,
 * `/skills/{quelle}/{skill}` und `/skills/audit/…`. Alles andere — auch Pfade mit `..` oder kodierten
 * Schrägstrichen — wird abgelehnt, damit über das Relay nichts anderes bei skills.sh erreichbar ist.
 */
export function skillRelayRequestFrom(path: unknown, query: unknown): SkillRelayRequest {
  return {path: validPath(path), query: validQuery(query)};
}

export function pathAndQueryOf(request: SkillRelayRequest): string {
  const search = new URLSearchParams(request.query).toString();
  return `/api/v1${request.path}${search ? `?${search}` : ""}`;
}

function validPath(value: unknown): string {
  if (typeof value !== "string" || value.length > maximumPathLength) throw invalid("Der Pfad ist ungültig.");
  const segments = value.split("/");
  if (segments[0] !== "" || segments[1] !== "skills" || segments.length > maximumSegments) {
    throw invalid("Dieser Pfad wird nicht weitergegeben.");
  }
  for (const segment of segments.slice(1)) {
    if (!segmentPattern.test(segment) || isTraversal(segment)) throw invalid("Der Pfad ist ungültig.");
  }
  return value;
}

function isTraversal(segment: string): boolean {
  try {
    const decoded = decodeURIComponent(segment);
    return decoded === "." || decoded === ".." || /[/\\\0]/.test(decoded);
  } catch {
    return true;
  }
}

function validQuery(value: unknown): Record<string, string> {
  if (value === undefined || value === null) return {};
  if (typeof value !== "object" || Array.isArray(value)) throw invalid("Die Parameter sind ungültig.");
  const result: Record<string, string> = {};
  for (const [key, item] of Object.entries(value)) {
    if (!allowedQueryParameters.has(key)) throw invalid(`Der Parameter „${key}“ wird nicht weitergegeben.`);
    if (typeof item !== "string" || item.length > maximumValueLength) throw invalid(`Der Parameter „${key}“ ist ungültig.`);
    result[key] = item;
  }
  return result;
}

function invalid(message: string): SkillRelayRequestError {
  return new SkillRelayRequestError(message);
}
