import {createHash} from "node:crypto";

export function localRuntimeActivationTokenHash(token: string): string {
  return sha256(token);
}

export function runtimeActivationSecretHash(secret: string): string {
  return sha256(secret);
}

function sha256(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}
