import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {type RuntimeLicenseVerdict} from "../../domain/entities/runtime-license-verification.js";
import {RuntimeLicenseError} from "./firestore-runtime-license-registry.js";

type ActivationVerifier = {
  verifyActiveActivation(license: SignedRuntimeLicense, activationSecret: string, now: Date): Promise<unknown>;
};

/**
 * Urteil über eine Aktivierung. Nur eine fachliche Ablehnung der Registry
 * (Lizenz fehlt, ist freigegeben, abgelaufen oder gehört einer anderen
 * Aktivierung) ergibt `revoked`; technische Fehler werden weitergeworfen, damit
 * eine Störung in der Cloud keine Runtime sperrt.
 */
export async function runtimeActivationVerdict(
  registry: ActivationVerifier,
  license: SignedRuntimeLicense,
  activationSecret: string,
  now: Date,
): Promise<RuntimeLicenseVerdict> {
  try {
    await registry.verifyActiveActivation(license, activationSecret, now);
    return "active";
  } catch (error) {
    if (error instanceof RuntimeLicenseError) return "revoked";
    throw error;
  }
}
