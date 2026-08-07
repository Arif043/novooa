import {createHash, randomBytes, randomUUID} from "crypto";

export function authorizationId(): string {
  return randomUUID();
}

export function authorizationCodeVerifier(): string {
  return randomBytes(48).toString("base64url");
}

export function codeChallenge(codeVerifier: string): string {
  return createHash("sha256").update(codeVerifier).digest("base64url");
}

export function subscriptionClientState(): string {
  return randomBytes(32).toString("base64url");
}
