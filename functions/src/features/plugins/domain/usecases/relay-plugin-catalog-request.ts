import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {SkillRelayRateLimitedError} from "../../../skills/domain/entities/skill-relay-request.js";
import {type RelayRateLimiter} from "../../../skills/domain/repositories/relay-rate-limiter.js";
import {pluginDownloadRequestFrom, type PluginCatalogEntry} from "../entities/plugin-catalog.js";
import {type PluginCatalog} from "../repositories/plugin-catalog.js";

/**
 * Nimmt Katalog-Anfragen einer Runtime entgegen: erst Lizenz, dann Anfrage prüfen, erst dann ein Token der Lizenz
 * entnehmen — Fehlversuche kosten also kein Kontingent und erreichen weder Firestore noch Storage.
 */
export class RelayPluginCatalogRequest {
  constructor(
    private readonly licenses: RuntimeRelayLicenseVerifier,
    private readonly limiter: RelayRateLimiter,
    private readonly catalog: PluginCatalog,
  ) {}

  async list(license: SignedRuntimeLicense): Promise<PluginCatalogEntry[]> {
    await this.admit(license);
    return this.catalog.list();
  }

  async download(license: SignedRuntimeLicense, id: unknown, version: unknown): Promise<Uint8Array> {
    const request = pluginDownloadRequestFrom(id, version);
    await this.admit(license);
    return this.catalog.download(request.id, request.version);
  }

  private async admit(license: SignedRuntimeLicense): Promise<void> {
    const active = await this.licenses.verify(license);
    // Eigener Schlüssel, damit Plugin-Downloads das Kontingent des Skill-Katalogs nicht aufbrauchen.
    const decision = await this.limiter.take(`plugins:${active.licenseId}`);
    if (!decision.allowed) throw new SkillRelayRateLimitedError(decision.retryAfterSeconds);
  }
}
