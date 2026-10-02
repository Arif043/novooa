import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {SkillRelayRateLimitedError, skillRelayRequestFrom} from "../entities/skill-relay-request.js";
import {type RelayRateLimiter} from "../repositories/relay-rate-limiter.js";
import {type SkillsCatalogResponse, type SkillsCatalogUpstream} from "../repositories/skills-catalog-upstream.js";

/**
 * Nimmt eine Katalog-Anfrage einer Runtime entgegen. Reihenfolge:
 * 1. Lizenz prüfen (Signatur, aktiv, Registry),
 * 2. Anfrage prüfen (nur lesende Katalogpfade, bekannte Parameter),
 * 3. erst dann ein Token der Lizenz entnehmen (Token Bucket),
 * 4. an den Upstream weiterreichen.
 * Fehlversuche mit ungültiger Lizenz oder verbotener Anfrage kosten also kein Token und erreichen weder den Eimer
 * noch den Upstream.
 */
export class RelaySkillsCatalogRequest {
  constructor(
    private readonly licenses: RuntimeRelayLicenseVerifier,
    private readonly limiter: RelayRateLimiter,
    private readonly upstream: SkillsCatalogUpstream,
  ) {}

  async execute(license: SignedRuntimeLicense, path: unknown, query: unknown): Promise<SkillsCatalogResponse> {
    const active = await this.licenses.verify(license);
    const request = skillRelayRequestFrom(path, query);
    const decision = await this.limiter.take(active.licenseId);
    if (!decision.allowed) throw new SkillRelayRateLimitedError(decision.retryAfterSeconds);
    return this.upstream.get(request);
  }
}
