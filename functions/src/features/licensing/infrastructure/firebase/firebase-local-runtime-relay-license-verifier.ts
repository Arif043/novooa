import {createPublicKey} from "node:crypto";
import {
  isActiveLocalRuntimeLicense,
  type LocalRuntimeLicense,
  type SignedLocalRuntimeLicense,
} from "../../domain/entities/local-runtime-license-lease.js";
import {type LocalRuntimeRelayLicenseVerifier} from
  "../../domain/repositories/local-runtime-relay-license-verifier.js";
import {verifiesLocalRuntimeLicense} from "../license-lease-crypto.js";
import {
  FirestoreLocalRuntimeLicenseRegistry,
} from "./firestore-local-runtime-license-registry.js";
import {localRuntimeLicenseSigningKey} from "./local-runtime-license-signing-key.js";

export class FirebaseLocalRuntimeRelayLicenseVerifier
implements LocalRuntimeRelayLicenseVerifier {
  constructor(
    private readonly registry = new FirestoreLocalRuntimeLicenseRegistry(),
    private readonly now: () => Date = () => new Date(),
  ) {}

  async verify(license: SignedLocalRuntimeLicense): Promise<LocalRuntimeLicense> {
    if (!this.isSignedAndActive(license)) throw new Error("Die Lizenz ist ungültig.");
    const active = await this.registry.licenseForId(license.payload.licenseId, this.now());
    if (active.workspaceId !== license.payload.workspaceId) {
      throw new Error("Die Lizenz ist ungültig.");
    }
    return active;
  }

  private isSignedAndActive(license: SignedLocalRuntimeLicense): boolean {
    return verifiesLocalRuntimeLicense(license, publicKeyPem()) &&
      isActiveLocalRuntimeLicense(license.payload, this.now());
  }
}

function publicKeyPem(): string {
  return String(createPublicKey(localRuntimeLicenseSigningKey.value())
    .export({format: "pem", type: "spki"}));
}
