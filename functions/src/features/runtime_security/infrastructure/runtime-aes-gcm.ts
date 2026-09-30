import {createCipheriv, createDecipheriv, randomBytes} from "node:crypto";

export type SealedValue = {iv: string; tag: string; ciphertext: string};

export function seal(value: Buffer, key: Buffer, aad: Buffer): SealedValue {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  cipher.setAAD(aad);
  const ciphertext = Buffer.concat([cipher.update(value), cipher.final()]);
  return {
    iv: iv.toString("base64url"), tag: cipher.getAuthTag().toString("base64url"),
    ciphertext: ciphertext.toString("base64url"),
  };
}

export function unseal(value: SealedValue, key: Buffer, aad: Buffer): Buffer {
  const decipher = createDecipheriv("aes-256-gcm", key, Buffer.from(value.iv, "base64url"));
  decipher.setAAD(aad);
  decipher.setAuthTag(Buffer.from(value.tag, "base64url"));
  return Buffer.concat([
    decipher.update(Buffer.from(value.ciphertext, "base64url")), decipher.final(),
  ]);
}

export function sealedValueFrom(value: unknown): SealedValue {
  if (value === null || typeof value !== "object") throw new Error("Ungültiger Geheimniswert.");
  const parsed = value as Record<string, unknown>;
  const iv = encodedString(parsed.iv, 12);
  const tag = encodedString(parsed.tag, 16);
  const ciphertext = encodedString(parsed.ciphertext);
  return {iv, tag, ciphertext};
}

export function encodedString(value: unknown, bytes?: number): string {
  if (typeof value !== "string" || Buffer.from(value, "base64url").toString("base64url") !== value ||
      (bytes !== undefined && Buffer.from(value, "base64url").length !== bytes)) {
    throw new Error("Ungültiges Verschlüsselungsformat.");
  }
  return value;
}
