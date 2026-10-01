import {timingSafeEqual} from "node:crypto";
import {runtimeActivationTokenFrom} from "../domain/entities/activation-token.js";
import {InvalidActivationTokenError} from "../domain/entities/runtime-license-errors.js";
import {localRuntimeActivationTokenHash} from "./license-activation-token-hash.js";

/** Hash für `RuntimeLicenseActivation.activationTokenHash`. */
export function activationTokenProofFor(normalizedToken: string): string {
  return localRuntimeActivationTokenHash(normalizedToken);
}

/**
 * Prüft in konstanter Zeit, ob `candidate` der eingelöste Token ist.
 * Schreibweise (Bindestriche, Kleinbuchstaben) wird wie bei der Aktivierung
 * normalisiert.
 */
export function matchesActivationTokenProof(proof: string | undefined, candidate: unknown): boolean {
  if (proof === undefined) return false;
  const normalized = normalizedTokenOrNull(candidate);
  if (normalized === null) return false;
  const expected = Buffer.from(proof, "hex");
  const actual = Buffer.from(activationTokenProofFor(normalized), "hex");
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

function normalizedTokenOrNull(candidate: unknown): string | null {
  try {
    return runtimeActivationTokenFrom(candidate);
  } catch (error) {
    if (error instanceof InvalidActivationTokenError) return null;
    throw error;
  }
}
