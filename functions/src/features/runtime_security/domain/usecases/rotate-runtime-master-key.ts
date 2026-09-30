import {type RuntimeKeyRepository} from "../repositories/runtime-key-repository.js";
import {type RuntimeSecretRotationStore} from "../repositories/runtime-secret-rotation-store.js";

export class RotateRuntimeMasterKey {
  constructor(
    private readonly keys: RuntimeKeyRepository,
    private readonly secrets: RuntimeSecretRotationStore,
  ) {}

  async execute(retireOldKeys = false): Promise<number> {
    const cipher = await this.keys.beginRotation();
    const count = await this.secrets.rewrapSecrets(cipher);
    await this.secrets.verifySecrets(cipher);
    await this.keys.completeRotation(retireOldKeys);
    return count;
  }
}
