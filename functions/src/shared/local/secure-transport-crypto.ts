import {
  createCipheriv,
  createDecipheriv,
  createPublicKey,
  diffieHellman,
  generateKeyPairSync,
  hkdfSync,
  randomBytes,
  type KeyObject,
} from "node:crypto";

/**
 * Kryptografie des verschlüsselten Transports (Version 1). Der Client spiegelt
 * jede Konstante in `lib/core/network/secure_transport/`; ein gemeinsamer
 * Testvektor stellt sicher, dass beide Seiten dieselben Schlüssel ableiten.
 *
 * - Schlüsselaustausch: X25519 (ephemere Schlüsselpaare auf beiden Seiten)
 * - Ableitung: HKDF-SHA256, Salt = Client-Nonce ‖ Server-Nonce, Info `novooa-transport-v1`,
 *   64 Byte = 32 Byte Client→Server ‖ 32 Byte Server→Client
 * - Verschlüsselung: AES-256-GCM, 12 Byte Zufalls-IV, Tag 16 Byte,
 *   Umschlag = Base64(IV ‖ Chiffretext ‖ Tag)
 * - Zusatzdaten (AAD): `novooa/1|<Kanal>|<req|res>|<Zähler>`
 */
export const transportInfo = "novooa-transport-v1";
export const nonceLength = 16;
const ivLength = 12;
const tagLength = 16;
const keyLength = 32;
const x25519SpkiPrefix = Buffer.from("302a300506032b656e032100", "hex");

export type Direction = "req" | "res";

export type SessionKeys = {clientToServer: Buffer; serverToClient: Buffer};

export type EphemeralKeyPair = {privateKey: KeyObject; publicKey: Buffer};

export function generateEphemeralKeyPair(): EphemeralKeyPair {
  const {privateKey, publicKey} = generateKeyPairSync("x25519");
  const spki = publicKey.export({format: "der", type: "spki"});
  return {privateKey, publicKey: spki.subarray(spki.length - keyLength)};
}

export function deriveSessionKeys(
  privateKey: KeyObject,
  peerPublicKey: Buffer,
  clientNonce: Buffer,
  serverNonce: Buffer,
): SessionKeys {
  const peer = createPublicKey({
    key: Buffer.concat([x25519SpkiPrefix, peerPublicKey]),
    format: "der",
    type: "spki",
  });
  const shared = diffieHellman({privateKey, publicKey: peer});
  const material = Buffer.from(hkdfSync(
    "sha256", shared, Buffer.concat([clientNonce, serverNonce]), transportInfo, keyLength * 2,
  ));
  return {
    clientToServer: material.subarray(0, keyLength),
    serverToClient: material.subarray(keyLength),
  };
}

export function additionalData(channelId: string, direction: Direction, counter: number): Buffer {
  return Buffer.from(`novooa/1|${channelId}|${direction}|${counter}`, "utf8");
}

export function seal(key: Buffer, plaintext: Buffer, aad: Buffer): string {
  const iv = randomBytes(ivLength);
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  cipher.setAAD(aad);
  const encrypted = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return Buffer.concat([iv, encrypted, cipher.getAuthTag()]).toString("base64");
}

/** Wirft, wenn Umschlag, Schlüssel oder Zusatzdaten nicht passen oder die Daten verändert wurden. */
export function open(key: Buffer, envelope: string, aad: Buffer): Buffer {
  const raw = Buffer.from(envelope, "base64");
  if (raw.length < ivLength + tagLength) throw new Error("Umschlag zu kurz.");
  const decipher = createDecipheriv("aes-256-gcm", key, raw.subarray(0, ivLength));
  decipher.setAAD(aad);
  decipher.setAuthTag(raw.subarray(raw.length - tagLength));
  return Buffer.concat([decipher.update(raw.subarray(ivLength, raw.length - tagLength)), decipher.final()]);
}
