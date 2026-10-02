import {type SkillRelayRequest} from "../../domain/entities/skill-relay-request.js";
import {type SkillsCatalogResponse, type SkillsCatalogUpstream} from "../../domain/repositories/skills-catalog-upstream.js";
import {signatureHeader, signSkillsRelayRequest, timestampHeader} from "./skills-relay-signature.js";

/**
 * Vercel routet in Projekten ohne Framework `api/[...x]` nur auf **ein** Pfadsegment. Der Katalogpfad geht deshalb
 * als Parameter `p` an die feste Adresse `/api/relay`; die übrigen Parameter folgen unverändert. Signiert wird genau
 * die Zeichenkette, die Vercel als Anfrage-URL sieht.
 */
export function proxyUrlFor(proxyUrl: string, request: SkillRelayRequest): URL {
  const url = new URL("/api/relay", proxyUrl);
  url.searchParams.set("p", request.path);
  for (const [key, value] of Object.entries(request.query)) url.searchParams.set(key, value);
  return url;
}

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

  async get(request: SkillRelayRequest): Promise<SkillsCatalogResponse> {
    const timestamp = this.now();
    const url = proxyUrlFor(this.proxyUrl(), request);
    const pathAndQuery = `${url.pathname}${url.search}`;
    const response = await this.request(url, {
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
