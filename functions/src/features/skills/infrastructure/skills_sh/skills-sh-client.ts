import {SkillCatalogError} from "../../domain/entities/skill-catalog.js";

export type SkillsShConfig = {
  /** Basis-Adresse der API oder des Proxys, z. B. `https://skills.sh/api/v1`. */
  baseUrl: string;
  /** Bearer-Token (Vercel OIDC); beim Proxy nicht nötig. */
  token?: string;
};

export type SkillsShClientDependencies = {
  request?: typeof fetch;
  now?: () => number;
  sleep?: (milliseconds: number) => Promise<void>;
};

const maximumWaitMilliseconds = 30_000;
const maximumRetries = 2;
const defaultRetryAfterSeconds = 5;
const maximumCacheEntries = 200;
const requestTimeoutMilliseconds = 30_000;

type CacheEntry = {value: unknown; expiresAt: number};

/**
 * Dünner Client für `https://skills.sh/api/v1` (600 Anfragen/Minute je Projekt). Er hält das Limit ein, statt es
 * auszureizen: Er merkt sich `X-RateLimit-Remaining/Reset`, wartet bei erschöpftem Kontingent kurz oder meldet die
 * Wartezeit, befolgt `Retry-After` bei 429, wiederholt 503 mit Backoff, hält Antworten nach `Cache-Control` vor und
 * fasst gleiche gleichzeitige Anfragen zusammen.
 */
export class SkillsShClient {
  private readonly request: typeof fetch;
  private readonly now: () => number;
  private readonly sleep: (milliseconds: number) => Promise<void>;
  private readonly cache = new Map<string, CacheEntry>();
  private readonly inFlight = new Map<string, Promise<unknown>>();
  private remaining: number | null = null;
  private resetAt = 0;

  constructor(private readonly config: SkillsShConfig, dependencies: SkillsShClientDependencies = {}) {
    this.request = dependencies.request ?? fetch;
    this.now = dependencies.now ?? Date.now;
    this.sleep = dependencies.sleep ?? ((milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds)));
  }

  async get<Body>(path: string, query: Record<string, string | number | undefined> = {}, defaultTtlSeconds = 60): Promise<Body> {
    const url = this.urlFor(path, query);
    const cached = this.cache.get(url);
    if (cached !== undefined && cached.expiresAt > this.now()) return cached.value as Body;
    const pending = this.inFlight.get(url);
    if (pending !== undefined) return pending as Promise<Body>;
    const started = this.fetchWithRetries<Body>(url, defaultTtlSeconds).finally(() => this.inFlight.delete(url));
    this.inFlight.set(url, started);
    return started;
  }

  private async fetchWithRetries<Body>(url: string, defaultTtlSeconds: number): Promise<Body> {
    for (let attempt = 0; ; attempt++) {
      await this.waitForQuota();
      const response = await this.send(url);
      this.learnQuota(response);
      if (response.ok) return this.remember(url, await response.json() as Body, response, defaultTtlSeconds);
      if (attempt < maximumRetries) {
        const wait = this.retryDelay(response, attempt);
        if (wait !== null && wait <= maximumWaitMilliseconds) {
          await this.sleep(wait);
          continue;
        }
      }
      throw await this.errorFor(response);
    }
  }

  private async send(url: string): Promise<Response> {
    try {
      return await this.request(url, {
        headers: {accept: "application/json", ...(this.config.token ? {authorization: `Bearer ${this.config.token}`} : {})},
        signal: AbortSignal.timeout(requestTimeoutMilliseconds),
      });
    } catch {
      throw new SkillCatalogError("skills.sh ist nicht erreichbar. Bitte später erneut versuchen.", "unavailable");
    }
  }

  /** Ist das Kontingent aufgebraucht, kurz warten — oder die Wartezeit melden, wenn sie zu lang ist. */
  private async waitForQuota(): Promise<void> {
    if (this.remaining === null || this.remaining > 0 || this.resetAt <= this.now()) return;
    const wait = this.resetAt - this.now();
    if (wait > maximumWaitMilliseconds) throw rateLimited(Math.ceil(wait / 1000));
    await this.sleep(wait);
    this.remaining = null;
  }

  private learnQuota(response: Response): void {
    const remaining = numberHeader(response, "x-ratelimit-remaining");
    const reset = numberHeader(response, "x-ratelimit-reset");
    if (remaining !== null) this.remaining = remaining;
    if (reset !== null) this.resetAt = this.now() + reset * 1000;
    if (response.status === 429) {
      this.remaining = 0;
      this.resetAt = this.now() + (retryAfterSeconds(response, this.now()) ?? defaultRetryAfterSeconds) * 1000;
    }
  }

  /** Wartezeit vor der nächsten Wiederholung in Millisekunden; `null`, wenn der Status nicht wiederholbar ist. */
  private retryDelay(response: Response, attempt: number): number | null {
    if (response.status === 429) return (retryAfterSeconds(response, this.now()) ?? defaultRetryAfterSeconds) * 1000;
    if (response.status === 503) return 1000 * 2 ** attempt;
    return null;
  }

  private remember<Body>(url: string, value: Body, response: Response, defaultTtlSeconds: number): Body {
    const ttl = maxAgeSeconds(response) ?? defaultTtlSeconds;
    if (ttl > 0) {
      if (this.cache.size >= maximumCacheEntries) this.cache.delete(this.cache.keys().next().value!);
      this.cache.set(url, {value, expiresAt: this.now() + ttl * 1000});
    }
    return value;
  }

  private async errorFor(response: Response): Promise<SkillCatalogError> {
    if (response.status === 429) return rateLimited(retryAfterSeconds(response, this.now()) ?? defaultRetryAfterSeconds);
    if (response.status === 404) return new SkillCatalogError("Der Skill wurde im Katalog nicht gefunden.", "not_found");
    if (response.status === 401) {
      return new SkillCatalogError("Der Zugang zu skills.sh ist nicht gültig (Token fehlt oder ist abgelaufen).", "unauthorized");
    }
    const body = await response.json().catch(() => ({})) as {message?: unknown};
    const detail = typeof body.message === "string" ? ` ${body.message}` : "";
    if (response.status === 400) return new SkillCatalogError(`skills.sh hat die Anfrage abgelehnt.${detail}`, "invalid");
    return new SkillCatalogError(`skills.sh ist vorübergehend nicht verfügbar (${response.status}).`, "unavailable");
  }

  private urlFor(path: string, query: Record<string, string | number | undefined>): string {
    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(query)) if (value !== undefined) params.set(key, String(value));
    const search = params.toString();
    return `${this.config.baseUrl.replace(/\/$/, "")}${path}${search ? `?${search}` : ""}`;
  }
}

function rateLimited(seconds: number): SkillCatalogError {
  return new SkillCatalogError(`Zu viele Anfragen an skills.sh. Bitte in ${seconds} Sekunden erneut versuchen.`, "rate_limited", seconds);
}

function numberHeader(response: Response, name: string): number | null {
  const value = Number(response.headers.get(name));
  return response.headers.get(name) !== null && Number.isFinite(value) ? value : null;
}

/** `Retry-After` als Sekunden oder HTTP-Datum. */
function retryAfterSeconds(response: Response, now: number): number | null {
  const header = response.headers.get("retry-after");
  if (header === null) return null;
  const seconds = Number(header);
  if (Number.isFinite(seconds)) return Math.max(1, Math.ceil(seconds));
  const date = Date.parse(header);
  return Number.isNaN(date) ? null : Math.max(1, Math.ceil((date - now) / 1000));
}

function maxAgeSeconds(response: Response): number | null {
  const header = response.headers.get("cache-control");
  if (header !== null && /no-store|no-cache/.test(header)) return 0;
  const match = header === null ? null : /(?:s-maxage|max-age)=(\d+)/.exec(header);
  return match === null ? null : Number(match[1]);
}
