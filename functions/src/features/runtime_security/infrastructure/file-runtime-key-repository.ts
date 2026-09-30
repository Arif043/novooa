import {readFile} from "node:fs/promises";
import {randomBytes, randomUUID} from "node:crypto";
import {type RuntimeKeyRepository} from "../domain/repositories/runtime-key-repository.js";
import {EnvelopeRuntimeFieldCipher} from "./envelope-runtime-field-cipher.js";
import {parseRuntimeKeyring, type RuntimeKeyring} from "./runtime-keyring.js";
import {writeDurableSecretFile} from "./durable-secret-file.js";
import {type RuntimeRotationSchedule, type RuntimeRotationStatus} from "../domain/repositories/runtime-rotation-schedule.js";

export class FileRuntimeKeyRepository implements RuntimeKeyRepository, RuntimeRotationSchedule {
  constructor(
    private readonly path: string,
    private readonly publish: (keyring: string) => void = () => {},
    private readonly now: () => Date = () => new Date(),
  ) {}

  async rotationStatus(): Promise<RuntimeRotationStatus> {
    const keyring = await this.load();
    if (!keyring.lastRotatedAt) {
      keyring.lastRotatedAt = this.now().toISOString();
      await this.save(keyring);
    }
    return {lastRotatedAt: keyring.lastRotatedAt, rotationPending: keyring.rotationPending};
  }

  async beginRotation(): Promise<EnvelopeRuntimeFieldCipher> {
    const keyring = await this.load();
    if (!keyring.rotationPending) {
      keyring.activeKeyId = randomUUID();
      keyring.keys[keyring.activeKeyId] = randomBytes(32).toString("base64");
      keyring.rotationPending = true;
      await this.save(keyring);
    }
    this.publish(JSON.stringify(keyring));
    return new EnvelopeRuntimeFieldCipher(JSON.stringify(keyring));
  }

  async completeRotation(retireOldKeys: boolean): Promise<void> {
    const keyring = await this.load();
    if (!keyring.rotationPending) throw new Error("Keine Master-Key-Rotation aktiv.");
    if (retireOldKeys) keyring.keys = {[keyring.activeKeyId]: keyring.keys[keyring.activeKeyId]};
    keyring.rotationPending = false;
    keyring.lastRotatedAt = this.now().toISOString();
    await this.save(keyring);
  }

  private async load(): Promise<RuntimeKeyring> {
    return parseRuntimeKeyring(await readFile(this.path, "utf8"));
  }

  private async save(keyring: RuntimeKeyring): Promise<void> {
    await writeDurableSecretFile(this.path, `${JSON.stringify(keyring)}\n`);
    this.publish(JSON.stringify(keyring));
  }
}
