import {hkdfSync, randomBytes} from "node:crypto";
import {type RuntimeFieldCipher} from "../domain/repositories/runtime-field-cipher.js";
import {type RuntimeKeyring, parseRuntimeKeyring} from "./runtime-keyring.js";
import {encodedString, seal, sealedValueFrom, type SealedValue, unseal} from "./runtime-aes-gcm.js";

type Envelope = {
  version: 1;
  masterKeyId: string;
  salt: string;
  wrappedKey: SealedValue;
  payload: SealedValue;
};

export class EnvelopeRuntimeFieldCipher implements RuntimeFieldCipher {
  private readonly keyring: RuntimeKeyring;

  constructor(serializedKeyring: string) {
    this.keyring = parseRuntimeKeyring(serializedKeyring);
  }

  encrypt(value: string, context: readonly string[]): string {
    const dataKey = randomBytes(32);
    try {
      const payload = seal(Buffer.from(value, "utf8"), dataKey, aadFor("payload", context));
      return JSON.stringify(this.wrap(dataKey, payload, context));
    } finally {
      dataKey.fill(0);
    }
  }

  decrypt(value: string, context: readonly string[]): string {
    const envelope = envelopeFrom(value);
    const dataKey = this.unwrap(envelope, context);
    try {
      return unseal(envelope.payload, dataKey, aadFor("payload", context)).toString("utf8");
    } finally {
      dataKey.fill(0);
    }
  }

  rewrap(value: string, context: readonly string[]): string {
    const envelope = envelopeFrom(value);
    const dataKey = this.unwrap(envelope, context);
    try {
      const plaintext = unseal(envelope.payload, dataKey, aadFor("payload", context));
      plaintext.fill(0);
      if (envelope.masterKeyId === this.keyring.activeKeyId) return value;
      return JSON.stringify(this.wrap(dataKey, envelope.payload, context));
    } finally {
      dataKey.fill(0);
    }
  }

  usesActiveKey(value: string): boolean {
    return envelopeFrom(value).masterKeyId === this.keyring.activeKeyId;
  }

  private wrap(dataKey: Buffer, payload: SealedValue, context: readonly string[]): Envelope {
    const masterKeyId = this.keyring.activeKeyId;
    const salt = randomBytes(32).toString("base64url");
    const wrappingKey = this.derive(masterKeyId, salt, context);
    try {
      const wrappedKey = seal(dataKey, wrappingKey, aadFor("wrap", context, masterKeyId, salt));
      return {version: 1, masterKeyId, salt, wrappedKey, payload};
    } finally {
      wrappingKey.fill(0);
    }
  }

  private unwrap(envelope: Envelope, context: readonly string[]): Buffer {
    const {masterKeyId, salt, wrappedKey} = envelope;
    const wrappingKey = this.derive(masterKeyId, salt, context);
    try {
      const key = unseal(wrappedKey, wrappingKey, aadFor("wrap", context, masterKeyId, salt));
      if (key.length !== 32) throw new Error("Ungültiger Datenschlüssel.");
      return key;
    } finally {
      wrappingKey.fill(0);
    }
  }

  private derive(id: string, salt: string, context: readonly string[]): Buffer {
    if (!Object.prototype.hasOwnProperty.call(this.keyring.keys, id)) throw new Error(`Runtime-Master-Key fehlt: ${id}`);
    const masterKey = Buffer.from(this.keyring.keys[id], "base64");
    try {
      return Buffer.from(hkdfSync("sha256", masterKey, Buffer.from(salt, "base64url"),
        aadFor("kdf", context), 32));
    } finally {
      masterKey.fill(0);
    }
  }
}

function aadFor(purpose: string, context: readonly string[], ...metadata: string[]): Buffer {
  if (context.length === 0 || context.some((part) => typeof part !== "string" || !part.length)) {
    throw new Error("Eindeutiger Feldkontext fehlt.");
  }
  return Buffer.from(JSON.stringify(["novooa-runtime-envelope", 1, purpose, context, metadata]));
}

function envelopeFrom(value: string): Envelope {
  const parsed: unknown = JSON.parse(value);
  if (parsed === null || typeof parsed !== "object") throw new Error("Ungültiges Geheimnisformat.");
  const envelope = parsed as Record<string, unknown>;
  if (envelope.version !== 1 || typeof envelope.masterKeyId !== "string") {
    throw new Error("Nicht unterstütztes Runtime-Geheimnisformat.");
  }
  return {
    version: 1, masterKeyId: envelope.masterKeyId, salt: encodedString(envelope.salt, 32),
    wrappedKey: sealedValueFrom(envelope.wrappedKey), payload: sealedValueFrom(envelope.payload),
  };
}
