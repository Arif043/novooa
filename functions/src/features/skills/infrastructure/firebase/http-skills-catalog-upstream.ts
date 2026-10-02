import {type SkillsCatalogResponse, type SkillsCatalogUpstream} from "../../domain/repositories/skills-catalog-upstream.js";
import {signatureHeader, signSkillsRelayRequest, timestampHeader} from "./skills-relay-signature.js";

const forwardedHeaders = ["content-type", "cache-control", "retry-after", "x-ratelimit-limit", "x-ratelimit-remaining", "x-ratelimit-reset"];
const timeoutMilliseconds = 25_000;

/** Ruft den Vercel-Proxy mit einer HMAC-Signatur auf; der Proxy ersetzt sie durch das OIDC-Token von skills.sh. */
export class HttpSkillsCatalogUpstream implements SkillsCatalogUpstream {
  constructor(
    private readonly proxyUrl: () => string,
    private readonly secret: () => string,
    private readonly request: typeof fetch = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  async get(pathAndQuery: string): Promise<SkillsCatalogResponse> {
    const timestamp = this.now();
    const response = await this.request(new URL(pathAndQuery, this.proxyUrl()), {
      method: "GET",
      headers: {
        accept: "application/json",
        [timestampHeader]: String(timestamp),
        [signatureHeader]: signSkillsRelayRequest(this.secret(), timestamp, "GET", pathAndQuery),
      },
      signal: AbortSignal.timeout(timeoutMilliseconds),
    });
    const headers: Record<string, string> = {};
    for (const name of forwardedHeaders) {
      const value = response.headers.get(name);
      if (value !== null) headers[name] = value;
    }
    return {status: response.status, body: await response.text(), headers};
  }
}
