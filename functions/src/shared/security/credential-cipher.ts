import {
  createCipheriv,
  createDecipheriv,
  randomBytes,
} from "crypto";

export class CredentialCipher {
  constructor(key: string, keyName = "MAIL_CONNECTOR_ENCRYPTION_KEY") {
    this.#key = keyFrom(key, keyName);
  }

  readonly #key: Buffer;

  encrypt(value: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv("aes-256-gcm", this.#key, iv);
    const encrypted = Buffer.concat([cipher.update(value, "utf8"), cipher.final()]);
    return [iv, cipher.getAuthTag(), encrypted]
      .map((part) => part.toString("base64url")).join(".");
  }

  decrypt(value: string): string {
    const parts = value.split(".");
    if (parts.length !== 3) throw new Error("Invalid encrypted credential.");
    const decipher = createDecipheriv(
      "aes-256-gcm", this.#key, Buffer.from(parts[0], "base64url"),
    );
    decipher.setAuthTag(Buffer.from(parts[1], "base64url"));
    return Buffer.concat([decipher.update(Buffer.from(parts[2], "base64url")), decipher.final()])
      .toString("utf8");
  }
}

function keyFrom(value: string, keyName: string): Buffer {
  const key = Buffer.from(value.trim(), "base64");
  if (key.length !== 32) throw new Error(`${keyName} must be 32 bytes.`);
  return key;
}
