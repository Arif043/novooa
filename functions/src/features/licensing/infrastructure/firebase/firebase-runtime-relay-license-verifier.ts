import {createPublicKey} from "node:crypto";
import {
  isActiveRuntimeLicense,
  type RuntimeLicense,
  type SignedRuntimeLicense,
} from "../../domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from
  "../../domain/repositories/runtime-relay-license-verifier.js";
import {verifiesRuntimeLicense} from "../license-lease-crypto.js";
import {
  FirestoreRuntimeLicenseRegistry,
} from "./firestore-runtime-license-registry.js";
import {localRuntimeLicenseSigningKey} from "./local-runtime-license-signing-key.js";

export class FirebaseRuntimeRelayLicenseVerifier
implements RuntimeRelayLicenseVerifier {
  constructor(
    private readonly registry = new FirestoreRuntimeLicenseRegistry(),
    private readonly now: () => Date = () => new Date(),
  ) {}

  async verify(license: SignedRuntimeLicense): Promise<RuntimeLicense> {
    if (!this.isSignedAndActive(license)) throw new Error("Die Lizenz ist ungültig.");
    const active = await this.registry.licenseForId(license.payload.licenseId, this.now());
    if (active.workspaceId !== license.payload.workspaceId) {
      throw new Error("Die Lizenz ist ungültig.");
    }
    return active;
  }

  private isSignedAndActive(license: SignedRuntimeLicense): boolean {
    return verifiesRuntimeLicense(license, publicKeyPem()) &&
      isActiveRuntimeLicense(license.payload, this.now());
  }
}

function publicKeyPem(): string {
  return String(createPublicKey(localRuntimeLicenseSigningKey.value())
    .export({format: "pem", type: "spki"}));
}
