import {createHash, randomBytes, randomUUID} from "crypto";

/** Kennung einer laufenden OAuth-Anmeldung; geht als `state` an den Anbieter. */
export function authorizationId(): string {
  return randomUUID();
}

export function authorizationCodeVerifier(): string {
  return randomBytes(48).toString("base64url");
}

export function codeChallenge(codeVerifier: string): string {
  return createHash("sha256").update(codeVerifier).digest("base64url");
}
