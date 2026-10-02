import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {pathAndQueryOf, skillRelayRequestFrom} from "../entities/skill-relay-request.js";
import {type SkillsCatalogResponse, type SkillsCatalogUpstream} from "../repositories/skills-catalog-upstream.js";

/**
 * Nimmt eine Katalog-Anfrage einer Runtime entgegen: Zuerst wird die Lizenz geprüft (Signatur, aktiv, in der
 * Registry), erst danach die Anfrage selbst; nur dann geht sie an den Upstream. Eine Rate-Begrenzung je Lizenz
 * (Token Bucket) kommt später an dieselbe Stelle, nach der Prüfung der Lizenz.
 */
export class RelaySkillsCatalogRequest {
  constructor(
    private readonly licenses: RuntimeRelayLicenseVerifier,
    private readonly upstream: SkillsCatalogUpstream,
  ) {}

  async execute(license: SignedRuntimeLicense, path: unknown, query: unknown): Promise<SkillsCatalogResponse> {
    await this.licenses.verify(license);
    return this.upstream.get(pathAndQueryOf(skillRelayRequestFrom(path, query)));
  }
}
