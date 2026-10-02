import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {SkillCatalogError} from "../../domain/entities/skill-catalog.js";

/** Wie eine Katalog-Anfrage zu skills.sh gelangt. Der Client darüber kümmert sich um Limits, Cache und Wiederholungen. */
export interface SkillsShTransport {
  /** `path` beginnt mit `/skills`. */
  send(path: string, query: URLSearchParams): Promise<Response>;
}

export type DirectSkillsShConfig = {
  /** Basis-Adresse der API, z. B. `https://skills.sh/api/v1`. */
  baseUrl: string;
  /** Bearer-Token (Vercel OIDC). */
  token?: string;
};

const requestTimeoutMilliseconds = 30_000;

/** Direkt gegen die skills.sh-API — nur mit eigenem Vercel-OIDC-Token sinnvoll (Entwicklung). */
export class DirectSkillsShTransport implements SkillsShTransport {
  constructor(private readonly config: DirectSkillsShConfig, private readonly request: typeof fetch = fetch) {}

  send(path: string, query: URLSearchParams): Promise<Response> {
    const search = query.toString();
    return this.request(`${this.config.baseUrl.replace(/\/$/, "")}${path}${search ? `?${search}` : ""}`, {
      headers: {accept: "application/json", ...(this.config.token ? {authorization: `Bearer ${this.config.token}`} : {})},
      signal: AbortSignal.timeout(requestTimeoutMilliseconds),
    });
  }
}

/**
 * Über das Relay in Firebase (`localRuntimeSkillsRelay`): Die Runtime weist sich mit ihrer signierten Lizenz aus;
 * das Relay prüft sie und reicht die Anfrage an den Vercel-Proxy weiter. Es liegt kein gemeinsames Geheimnis bei
 * der Runtime.
 */
export class LicenseRelaySkillsShTransport implements SkillsShTransport {
  constructor(
    private readonly relayUrl: string,
    private readonly license: () => SignedRuntimeLicense | null,
    private readonly request: typeof fetch = fetch,
  ) {
    if (new URL(relayUrl).protocol !== "https:") throw new Error("Das Skills-Relay muss HTTPS verwenden.");
  }

  send(path: string, query: URLSearchParams): Promise<Response> {
    const license = this.license();
    if (license === null) {
      throw new SkillCatalogError("Für den Katalog ist eine aktive Lizenz nötig. Aktiviere die Runtime zuerst.", "unauthorized");
    }
    return this.request(this.relayUrl, {
      method: "POST",
      headers: {accept: "application/json", "content-type": "application/json"},
      body: JSON.stringify({license, path, query: Object.fromEntries(query)}),
      signal: AbortSignal.timeout(requestTimeoutMilliseconds),
    });
  }
}
