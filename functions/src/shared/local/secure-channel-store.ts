import {randomBytes} from "node:crypto";
import {
  deriveSessionKeys,
  generateEphemeralKeyPair,
  nonceLength,
  type SessionKeys,
} from "./secure-transport-crypto.js";

const replayWindow = 128;

/**
 * Ein ausgehandelter Kanal. Anfragen tragen einen Zähler; ein Zähler wird nur
 * einmal akzeptiert und muss im Fenster der letzten [replayWindow] Zähler
 * liegen. Das schützt vor dem Wiedereinspielen mitgeschnittener Anfragen und
 * erlaubt trotzdem parallele Anfragen, die sich auf dem Netz überholen.
 */
export class SecureChannel {
  private highest = 0;
  private readonly seen = new Set<number>();
  lastUsedAt = Date.now();

  constructor(readonly id: string, readonly keys: SessionKeys) {}

  /** Prüft und markiert in einem Schritt (synchron, damit parallele Wiederholungen nicht beide durchkommen). */
  acceptCounter(counter: number): boolean {
    if (!Number.isSafeInteger(counter) || counter < 1) return false;
    if (counter <= this.highest - replayWindow || this.seen.has(counter)) return false;
    this.seen.add(counter);
    this.highest = Math.max(this.highest, counter);
    for (const known of this.seen) if (known <= this.highest - replayWindow) this.seen.delete(known);
    this.lastUsedAt = Date.now();
    return true;
  }
}

export type HandshakeResult = {channelId: string; serverPublicKey: Buffer; serverNonce: Buffer};

export type SecureChannelStoreOptions = {maxChannels?: number; idleMilliseconds?: number; now?: () => number};

/** Hält alle Kanäle im Speicher; ein Neustart der Runtime verwirft sie, der Client verhandelt dann neu. */
export class SecureChannelStore {
  private readonly channels = new Map<string, SecureChannel>();
  private readonly maxChannels: number;
  private readonly idleMilliseconds: number;
  private readonly now: () => number;

  constructor(options: SecureChannelStoreOptions = {}) {
    this.maxChannels = options.maxChannels ?? 512;
    this.idleMilliseconds = options.idleMilliseconds ?? 12 * 60 * 60 * 1000;
    this.now = options.now ?? Date.now;
  }

  open(clientPublicKey: Buffer, clientNonce: Buffer): HandshakeResult {
    this.evict();
    const pair = generateEphemeralKeyPair();
    const serverNonce = randomBytes(nonceLength);
    const keys = deriveSessionKeys(pair.privateKey, clientPublicKey, clientNonce, serverNonce);
    const channel = new SecureChannel(randomBytes(16).toString("base64url"), keys);
    channel.lastUsedAt = this.now();
    this.channels.set(channel.id, channel);
    return {channelId: channel.id, serverPublicKey: pair.publicKey, serverNonce};
  }

  find(channelId: string): SecureChannel | undefined {
    const channel = this.channels.get(channelId);
    if (channel === undefined) return undefined;
    if (this.now() - channel.lastUsedAt > this.idleMilliseconds) {
      this.channels.delete(channelId);
      return undefined;
    }
    return channel;
  }

  get size(): number {
    return this.channels.size;
  }

  private evict(): void {
    for (const [id, channel] of this.channels) {
      if (this.now() - channel.lastUsedAt > this.idleMilliseconds) this.channels.delete(id);
    }
    while (this.channels.size >= this.maxChannels) {
      const oldest = [...this.channels.values()].reduce((a, b) => (a.lastUsedAt <= b.lastUsedAt ? a : b));
      this.channels.delete(oldest.id);
    }
  }
}

export {nonceLength};
